class CourseCollaborator < ApplicationRecord
  belongs_to :course
  belongs_to :user

  # Creator permissions
  # Course: View, Edit, Delete, Publish, Invite.
  # Question: Create, View, Edit, Delete, Publish.
  # Assets: Create, View, Edit, Delete.

  # Co-Creator permissions - same as creator, except no invitations to other collaborators
  # Course: View, Edit, Delete, Publish.
  # Question: Create, View, Edit, Delete, Publish.
  # Assets: Create, View, Edit, Delete.
  
  # Editor permissions
  # Course: View, Edit.
  # Question: Create, View, Edit, Delete-Own.
  # Assets: Create, View, Edit, Delete-Own.

  enum role: {
    co_creator: 1,
    editor: 2,
    # More roles to be added, but only these two roles will have author visibility
  }, _prefix: true
end
