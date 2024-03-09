class TaskSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name, :points, :active
  has_many :chores
end
