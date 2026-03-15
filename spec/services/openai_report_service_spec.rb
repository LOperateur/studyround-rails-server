require 'rails_helper'

RSpec.describe OpenaiReportService do
  let(:session_items) do
    [
      {
        "question_id" => 1,
        "multiplier" => 1,
        "user_answer" => [2],
        "correct_answer" => [1],
        "correct" => false,
        "question" => {
          "id" => 1,
          "question" => "What is 2+2?",
          "options" => [
            { "option_text" => "3", "option_index" => 0 },
            { "option_text" => "4", "option_index" => 1 },
          ],
          "answer" => [1],
          "tags" => ["math", "arithmetic"],
          "explanation" => "2+2 equals 4",
          "multiplier" => 1,
          "course" => { "id" => 1, "title" => "Basic Math" },
        },
      },
      {
        "question_id" => 2,
        "multiplier" => 1,
        "user_answer" => [1],
        "correct_answer" => [1],
        "correct" => true,
        "question" => {
          "id" => 2,
          "question" => "What is 3+3?",
          "options" => [
            { "option_text" => "6", "option_index" => 0 },
            { "option_text" => "7", "option_index" => 1 },
          ],
          "answer" => [1],
          "tags" => ["math", "arithmetic"],
          "explanation" => "3+3 equals 6",
          "multiplier" => 1,
          "course" => { "id" => 1, "title" => "Basic Math" },
        },
      },
    ]
  end

  let(:result) do
    Result.new(
      score: 1,
      total: 2,
      duration: 300,
      elapsed_time: 200,
      session_type: :practice,
      session_items: session_items,
      num_questions: 2,
    )
  end

  describe "#generate" do
    it "returns an error when session_items is blank" do
      result.session_items = nil
      service = described_class.new(result)
      response = service.generate
      expect(response[:error]).to eq("No session items available")
    end

    it "calls OpenAI and returns a report" do
      mock_response = {
        "choices" => [{ "message" => { "content" => "Great job! Here is your report..." } }],
        "usage" => { "prompt_tokens" => 500, "completion_tokens" => 300 },
      }

      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(mock_response)

      service = described_class.new(result)
      response = service.generate

      expect(response[:report]).to eq("Great job! Here is your report...")
      expect(response[:prompt_tokens]).to eq(500)
      expect(response[:completion_tokens]).to eq(300)
      expect(response[:error]).to be_nil
    end

    it "handles OpenAI errors gracefully" do
      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_raise(StandardError.new("API rate limit exceeded"))

      service = described_class.new(result)
      response = service.generate

      expect(response[:report]).to be_nil
      expect(response[:error]).to eq("API rate limit exceeded")
    end

    it "strips question assets from prompt data" do
      session_items_with_assets = [
        {
          "question_id" => 1,
          "multiplier" => 1,
          "user_answer" => [1],
          "correct_answer" => [1],
          "correct" => true,
          "question" => {
            "id" => 1,
            "question" => "Read the passage and answer",
            "options" => [
              { "option_text" => "Yes", "option_index" => 0, "option_image_asset_id" => 5, "option_image_asset" => { "url" => "http://example.com/image.png" } },
            ],
            "passage_asset" => { "id" => 10, "content" => "Long passage text..." },
            "question_image_asset" => { "id" => 11, "url" => "http://example.com/qimage.png" },
            "tags" => ["reading"],
            "multiplier" => 1,
          },
        },
      ]

      result.session_items = session_items_with_assets

      service = described_class.new(result)
      items = service.send(:prepare_prompt_items, session_items_with_assets)

      expect(items.first).not_to have_key("passage_asset")
      expect(items.first).not_to have_key("question_image_asset")
      expect(items.first["options"].first).not_to have_key("option_image_asset")
      expect(items.first["options"].first).not_to have_key("option_image_asset_id")
    end

    it "samples questions for multi-course sessions" do
      multi_items = []
      2.times do |course_idx|
        20.times do |q_idx|
          multi_items << {
            "question_id" => course_idx * 20 + q_idx,
            "multiplier" => 1,
            "user_answer" => [1],
            "correct_answer" => [1],
            "correct" => q_idx.even?,
            "question" => {
              "id" => course_idx * 20 + q_idx,
              "question" => "Question #{q_idx}?",
              "options" => [{ "option_text" => "Answer", "option_index" => 0 }],
              "tags" => ["topic_#{course_idx}"],
              "multiplier" => 1,
              "course" => { "id" => course_idx + 1, "title" => "Course #{course_idx + 1}" },
            },
          }
        end
      end

      service = described_class.new(result)
      items = service.send(:prepare_prompt_items, multi_items)

      expect(items.size).to be <= 26
    end
  end
end
