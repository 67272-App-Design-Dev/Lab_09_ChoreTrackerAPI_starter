# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

require 'factory_bot_rails'

# Step 1: create some children
alex = FactoryBot.create(:child)
rachel = FactoryBot.create(:child, first_name: "Rachel", active: false)
mark = FactoryBot.create(:child, first_name: "Mark")


# Step 2: create some tasks
dishes = FactoryBot.create(:task)
wood = FactoryBot.create(:task, name: "Stack wood", active: false)
sweep = FactoryBot.create(:task, name: "Sweep floor")
shovel = FactoryBot.create(:task, name: "Shovel driveway", points: 3)
mow = FactoryBot.create(:task, name: "Mow grass", points: 2)

# Step 3: create some chores
ac1 = FactoryBot.create(:chore, child: alex, task: dishes)
mc1 = FactoryBot.create(:chore, child: mark, task: sweep)
ac2 = FactoryBot.create(:chore, child: alex, task: sweep, due_on: 2.days.from_now.to_date)
mc2 = FactoryBot.create(:chore, child: mark, task: dishes, due_on: 2.days.from_now.to_date)
ac3 = FactoryBot.create(:chore, child: alex, task: shovel, due_on: 2.days.ago.to_date, completed: true)
ac4 = FactoryBot.create(:chore, child: alex, task: dishes, due_on: Date.today, completed: true)
mc3 = FactoryBot.create(:chore, child: mark, task: sweep, due_on: Date.today, completed: true)