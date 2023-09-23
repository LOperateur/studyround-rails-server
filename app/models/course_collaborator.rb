class CourseCollaborator < ApplicationRecord
  belongs_to :course
  belongs_to :user

  # Creator permissions
  # Course: View, Edit, Delete, Publish, Invite, Close(Test).
  # Question: Create, View, Edit, Delete, Publish.
  # Assets: Create, View, Edit, Delete.
  # Notes: Create, View, Edit-Own, Delete-Own, Resolve.

  # Co-Creator permissions
  # Course: View, Edit, Delete, Publish.
  # Question: Create, View, Edit, Delete, Publish.
  # Assets: Create, View, Edit, Delete.
  # Notes: Create, View, Edit-Own, Delete-Own.
  
  # Editor permissions
  # Course: View, Edit.
  # Question: Create, View, Edit, Delete-Own.
  # Assets: Create, View, Edit, Delete-Own.
  # Notes: Create, View, Edit-Own, Delete-Own.

  enum role: {
    co_creator: 1,
    editor: 2,
    # More roles to be added, but only these two roles will have author visibility
  }, _prefix: true
end
