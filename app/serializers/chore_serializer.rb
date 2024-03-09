class ChoreSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :child_id, :due_on
  attribute :completed do |object|
    object.status
  end
  attribute :task do |object|
    ChoreTaskSerializer.new(object.task)
  end
end
