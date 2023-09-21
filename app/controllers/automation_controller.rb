class AutomationController < ApplicationController
  skip_before_action :authorize!

  def assign_course
    creator_username, reviewer_username = parse_trello_course_desc(assign_course_params[:description])

    creator = User.find_by!(username: creator_username)
    reviewer = User.find_by!(username: reviewer_username)

    assignment = assign_course_params[:assign_to]
    course = Course.non_deleted_courses.find_by!(title: assign_course_params[:course])

    if assignment == "creator"
      course.creator = creator
      assignee_trello_id = username_to_trello_id_map[creator.username.to_sym]
    elsif assignment == "reviewer"
      course.creator = reviewer
      assignee_trello_id = username_to_trello_id_map[reviewer.username.to_sym]
    else
      course.creator = User.find_by!(email: "admin@studyround.com")
      assignee_trello_id = username_to_trello_id_map[creator.username.to_sym]
    end

    course.save!

    # Now Assign the proper members to the Trello Card
    conn = Faraday.new(
      url: "https://api.trello.com",
      headers: { 'Content-Type' => 'application/json' }
    )
    response = conn.post("/1/cards/#{assign_course_params[:card_id]}/idMembers") do |req|
      req.params['value'] = assignee_trello_id
      req.params['key'] = ENV['TRELLO_API_KEY']
      req.params['token'] = ENV['TRELLO_API_TOKEN']
    end

    render json: { id: course.id }, status: :ok
  end

  def create_course
    course = User.find_by(email: "admin@studyround.com").courses.create!(title: create_course_params[:title], about: create_course_params[:title])

    render json: { id: course.id }, status: :created
  end

  private

  def parse_trello_course_desc(string)
    pattern = /\[(.*?)\]/
    creator, reviewer = string.split("\n").map do |line|
      match = line.match(pattern)
      match[1] if match
    end
    [creator, reviewer]
  end

  def username_to_trello_id_map
    {
      # Admins
      "ulearn": "5d7fca71118a894284ce5818",
      "mofeejegi": "5b83d7af75612b1212f3a7f1",
      "caleb": "5d478ab77a6be628c6573af0",
      "karo": "6473baa1ae62fda376e8cc60",

      # Managers
      "jolomi.pm": "647cbc0ca4b63ce23b371917",
      "chika.pm": "5c0699f0c7832e592fa13101",

      # Content Providers
      "abram.ekhator.cp": "634c6827017a99006f9cfb67",
      "debby.becky.cp": "646c7dff1b89f0436877e0fe",
      "ebu.excellent.cp": "646cbb9302e5ce43be681b20",
      "eseosa.edemakhiota.cp": "646b3d5dda5d0ef2fc6430e8",
      "fejiro.okome.cp": "64714bef0ed6efeaa0bdb5c3",
      "joy.igbo.cp": "620117fdf19332864c8ae7e3",
      "joy.omere.cp": "646a62d3c7d3594dfb4f02b7",
      "odianosen.cp": "646a8d469bef89ff83dd0a78",
      "onichabor.tochi.cp": "6025a40988927378cba9fbd1",
      "tinyan.wendy.cp": "646b1c12416747d7e04e8014",
    }
  end

  def assign_course_params
    params.permit(:course, :description, :assign_to, :card_id)
  end

  def create_course_params
    params.permit(:title)
  end
end
