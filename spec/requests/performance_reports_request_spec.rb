require 'rails_helper'

RSpec.describe "Performance Reports", type: :request do
  let(:user) do
    User.create!(
      username: "reportuser",
      email: "report@example.com",
      password: "password123",
      password_confirmation: "password123",
    )
  end

  let(:other_user) do
    User.create!(
      username: "otheruser",
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
    )
  end

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
          "options" => [{ "option_text" => "4", "option_index" => 0 }],
          "answer" => [1],
          "tags" => ["math"],
          "multiplier" => 1,
        },
      },
    ]
  end

  let(:result) do
    Result.create!(
      user: user,
      score: 1,
      total: 2,
      duration: 300,
      session_items: session_items,
      session_type: :practice,
    )
  end

  let(:auth_token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:other_auth_token) { JsonWebToken.encode({ user_id: other_user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{auth_token}" } }
  let(:other_auth_headers) { { "Authorization" => "Bearer #{other_auth_token}" } }

  before do
    mock_response = {
      "choices" => [{ "message" => { "content" => "AI generated report content" } }],
      "usage" => { "prompt_tokens" => 500, "completion_tokens" => 300 },
    }
    client = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat).and_return(mock_response)
  end

  describe "POST /results/:result_id/report" do
    it "generates a report for the authenticated user" do
      post "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["report_content"]).to eq("AI generated report content")
      expect(json["data"]["status"]).to eq("completed")
    end

    it "returns existing report on repeated calls (idempotency)" do
      post "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:ok)

      post "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:ok)

      expect(PerformanceReport.where(result: result).count).to eq(1)
    end

    it "forbids generating a report for another user's result" do
      post "/results/#{result.id}/report", headers: other_auth_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns error when session items are missing" do
      result.update!(session_items: nil)
      post "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:bad_request)
    end

    it "returns error for study session type" do
      result.update!(session_type: :study)
      post "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /results/:result_id/report" do
    it "returns the report for the authenticated user" do
      PerformanceReport.create!(
        result: result,
        user: user,
        status: :completed,
        report_content: "Existing report content",
        prompt_tokens: 400,
        completion_tokens: 200,
      )

      get "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["report_content"]).to eq("Existing report content")
    end

    it "returns 404 when no report exists" do
      get "/results/#{result.id}/report", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it "forbids viewing another user's report" do
      PerformanceReport.create!(
        result: result,
        user: user,
        status: :completed,
        report_content: "Report",
      )

      get "/results/#{result.id}/report", headers: other_auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
