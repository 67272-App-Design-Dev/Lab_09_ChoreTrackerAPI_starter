class ChoreTaskSerializer
  include FastJsonapi::ObjectSerializer
  set_type :task
  attributes :id, :name
end
