# Objectives

- Filtering and Ordering the index action
- Stateless authentication for the API
- Versioning the API
- Throttling API usage

# Lab 9: Choretracker API, Week 2

**The starter code for this week's lab is the solution to last week's lab.**

**If you have any issues with swagger docs not working properly - clear your cache. In Google Chrome, a hard reload should work.**

**If you are using the starter code from GitHub, make sure you `bundle install`, `rails db:migrate`, and `rails db:seed` before getting started.**

## Part 1 - Filtering and Ordering

One thing that we will be improving upon in this lab is filtering and ordering. This is mainly for the the index action of each controller and allows users of your API to filter out and order the list of objects. For example, if you want to get all the active tasks right now, you will have to hit the `/tasks` endpoint to get all the tasks back and then filter out the inactive ones manually using Javascript. However, a better option would be to pass in an active parameter that states what you want. So for the example, `/tasks?active=true` will get you all the active tasks, `/tasks?active=false` will get you all the inactive tasks, and `/tasks` will get you all the tasks. With the format, you can concat different filters and ordering together.

1. Let's first add this feature to the children endpoint! Open up the `child.rb` model file first and notice the scopes that are present (:active and :alphabetical). :active is a filtering scope and :alphabetical is a ordering scope. In this case, we will probably need another scope called `:inactive` to be the opposite of the :active filtering scope. Add the following :inactive scope to the child model file:

   ```ruby
   scope :inactive, -> {where(active: false)}
   ```

2. Now go the ChildrenController and let's add this new active filter to the index action. In this case, the `:active` param will be the one that triggers the filter and do nothing if the param isn't present. Also the only reason that we are checking if it's equal to the string "true" is that params are all treated as strings. Copy the following code into the index action (ask a TA for help if you don't understand the logic here):

   ```ruby
   def index
     @children = Child.all
     if(params[:active].present?)
       @children = params[:active] == "true" ? @children.active : @children.inactive
     end

     render json: ChildSerializer.new(@children)
   end
   ```

3. Since there was also an `:alphabetical` ordering scope, we will need to add that to the index action too. In this case, it will behave slightly different than the filtering scope. This is because it will only alphabetically order the children if the `:alphabetical` param is present and true. Add the following right after the active filter param in the index action (**Note:** The reasons why we are checking if the param is equal to the string "true" rather than the boolean is because all params are interpreted as strings initially):

   ```ruby
   if params[:alphabetical].present? && params[:alphabetical] == "true"
     @children = @children.alphabetical
   end
   ```

4. Now before we test this out, we will need to add the proper params to the swagger docs. Add the following `:query` params to the ChildrenController's swagger docs' index action and test it out (**Note**: don't forget to run `rails swagger:docs` afterward, if the application doesn't update, try opening an incognito browser or clearing your browser's cache):

   ```ruby
   param :query, :active, :boolean, :optional, "Filter on whether or not the child is active"
   param :query, :alphabetical, :boolean, :optional, "Order children by alphabetical"
   ```

5. After you tested everything out for children with swagger docs, we will move on to doing the same thing for tasks. Since Tasks is basically the same as Children, you will be completing the `:active` and `:alphabetical` filtering/ordering scopes on your own. (**Note**: Make sure you add the necessary scopes to the task model.)

6. Now we'll implement some filters for the Chores model. Chores is a bit more complicated but not that much. All the necessary scopes are there for you. You will be creating the filtering params on your own for `:done` and `:upcoming` (where `:pending` and `:past` are the opposite scopes respectively). Also, you will be creating the ordering params `:chronological` and `:by_task`.

7. Make sure you add all the appropriate swagger docs to the index actions of each controller and test out the filtering/ordering params.

---

**STOP**: Show a TA that you have all the filtering and ordering params working for all the controllers.

---

## Part 2 - Token Authentication

1. Now we will tackle authentication for API's since we don't want just anyone modifying the chores. (It would be a hoot to let the children just mark off their own chores regardless if they were actually done or not. Even better would be to allow children to reassign chores to siblings!) This will be slightly different from authentication for regular Rails applications mainly because the authentication will be stateless and we will be using a token (instead of an email and password). For this to work, we will first need to create a User model. Follow the specifications below and generate a new User model and run `rails db:migrate`. Note that there is still an email and password because we still want there to be a way later on for users to retrieve their authentication token (if they forgot it) by authentication through email and password.

   - User
     - email (string)
     - password_digest (string)
     - api_key (string)
     - active (boolean)

   Make sure you run `rails db:migrate` so that the schema is updated with this new model!

2. For now let's fill the User model with some validations. This is pretty standard and we have already done something similar before, so just copy paste the code below to your User model.

   ```ruby
   class User < ApplicationRecord
     has_secure_password

     validates_presence_of :email
     validates_uniqueness_of :email, allow_blank: true
     validates_presence_of :password, on: :create
     validates_presence_of :password_confirmation, on: :create
     validates_confirmation_of :password, message: "does not match"
     validates_length_of :password, minimum: 4, message: "must be at least 4 characters long", allow_blank: true
   end
   ```

3. So the general idea of the `api_key` is so that when someone sends a GET/POST/etc. request to your API, they will also need to provide the token in a header. Your API will then try to authenticate with that token and see what authorization that user has. This means that the `api_key` needs to be unique so we will not be allowing users to change/create the api_key. Instead, we will be generating a random api_key for each user when it is created. Therefore we will write a new callback function in the model code for creating the api_key. The following is the new model code. **Please understand it before continuing, or else everything will be rather confusing!** (**Note:** Don't forget to add the `gem 'bcrypt'` to the Gemfile for passwords and run bundle install).

   ```ruby
   class User < ApplicationRecord
     has_secure_password

     validates_presence_of :email
     validates_uniqueness_of :email, allow_blank: true
     validates_presence_of :password, on: :create
     validates_presence_of :password_confirmation, on: :create
     validates_confirmation_of :password, message: "does not match"
     validates_length_of :password, minimum: 4, message: "must be at least 4 characters long", allow_blank: true

     validates_uniqueness_of :api_key

     # Callback to create the API key
     before_create :generate_api_key

     private
     def generate_api_key
       begin
         self.api_key = SecureRandom.hex
       end while User.exists?(api_key: self.api_key)
     end
   end
   ```

   Once we have this `User` class, go into rails console and quickly create a new user with the command:

   ```ruby
   User.create({email:"jlp@starfleet.org", password: "secret", password_confirmation: "secret", active: true})
   ```

4. Now we should create the User controller and the Swagger Docs for the controller. This should be quick since you have done this already for all the other controllers. (**Note:** make sure that the user_params method only permits these parameters because we don't want them creating their own api_key: `params.permit(:email, :password, :password_confirmation, :active))` After you are done, verify that it is the same as below and make sure the create documentation has the right form parameters. **Also add the user resources to the routes.rb and run `rails swagger:docs`**

   ```ruby
   class UsersController < ApplicationController
     # Swagger Docs
     swagger_controller :users, "Users Management"

     swagger_api :index do
       summary "Fetches all Users"
       notes "This lists all the users"
     end

     swagger_api :show do
       summary "Shows one User"
       param :path, :id, :integer, :required, "User ID"
       notes "This lists details of one user"
       response :not_found
       response :not_acceptable
     end

     swagger_api :create do
       summary "Creates a new User"
       param :form, :email, :string, :required, "Email"
       param :form, :password, :password, :required, "Password"
       param :form, :password_confirmation, :password, :required, "Password Confirmation"
       param :form, :active, :boolean, :required, "active"
       response :not_acceptable
     end

     swagger_api :destroy do
       summary "Deletes an existing User"
       param :path, :id, :integer, :required, "User Id"
       response :not_found
       response :not_acceptable
     end


     # Main controller code
     before_action :set_user, only: [:show, :update, :destroy]

     # GET /users
     def index
       @users = User.all

       render json: @users
     end

     # GET /users/1
     def show
       render json: @user
     end

     # POST /users
     def create
       @user = User.new(user_params)

       if @user.save
         render json: @user, status: :created, location: @user
       else
         render json: @user.errors, status: :unprocessable_entity
       end
     end

     # DELETE /users/1
     def destroy
       @user.destroy
     end

     private
     def set_user
       @user = User.find(params[:id])
     end

     def user_params
       params.permit(:email, :password, :password_confirmation, :active)
     end
   end
   ```

5. We should also create a new serializer for users since we really don't want to display the password_digest, but we do need to show the api_key. **Make sure to call the serializers in the controller actions.**

6. We can now start up the rails server and test out whether or not our user model creation worked! Create a new user using Swagger and **save the api_key from the response**, this is **very important** for the next steps!

7. Next we need to actually implement the authentication with the tokens so that nobody can modify anything in the system without having a proper token. You will need to add the following to the ApplicationController. This uses the built-in `authenticate_with_http_token` method which checks if it is a valid token and if anything fails, it will just render the Bad Credentials JSON. How it works is that every request that comes through has to have an Authorization header with the specified token and that is what rails will check in order to authenticate. Also for simplicity, we authenticated for all actions in all controllers by putting a before_action in the ApplicationController.

   ```ruby
   class ApplicationController < ActionController::API
     include ActionController::HttpAuthentication::Token::ControllerMethods

     before_action :authenticate

     protected

     def authenticate
       authenticate_token || render_unauthorized
     end

     def authenticate_token
       authenticate_with_http_token do |token, options|
         @current_user = User.find_by(api_key: token)
       end
     end

     def render_unauthorized(realm = "Application")
       self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
       render json: {error: "Bad Credentials"}, status: :unauthorized
     end
   end
   ```

8. If you restart the server now and try to use Swagger to test out any of the endpoints in any controller, you will be faced with the 'Bad Credentials' message. To fix this we need to change the swagger docs so that it will pass along the token in the headers of every request. There are two ways to do this, one way is to add another header param to every single endpoint; another way is to add a setup method for swagger docs to pick up. In order to do this, all we need to do is write this singleton class within in the `ApplicationController` class so that it will affect all of the other controllers. This code goes to all the subclasses of `ApplicationController` and then adds the header param to each of the actions. (**Note:** Make sure you put this code within the `ApplicationController` class)

   ```ruby
   class << self
     def inherited(subclass)
       super
       subclass.class_eval do
         setup_basic_api_documentation
       end
     end

     private
     def setup_basic_api_documentation
       [:index, :show, :create, :update, :delete].each do |api_action|
         swagger_api api_action do
           param :header, 'Authorization', :string, :required, 'Authentication token in the format of: Token token=<token>'
         end
       end
     end
   end
   ```

9. Make sure you run `rails swagger:docs`, start up the server and check out the swagger docs. For each endpoint, there should be a header param. In order to successfully hit any of the endpoints, you will need to fill out this param too. This is a little bit more complicated as before since rails has its own format/way to do things. In the input box, enter this text exactly (including the actual word Token and Token=) `Token token=<api_key>` and replace `<api_key>` with the key from the user you created before. Now check that the API works with the token authentication!

10. Now that you have the token authentication implemented for each of the endpoints, there's no way for someone to access the API if they forgot their token. However, a user will most likely remember their email/password and forget their api_key, which is why we will need to create one more endpoint where users will be able to retrieve their token with their correct email/password. Let's call this endpoint `/token`. **Ask a TA if you don't understand the purpose of this new endpoint!** First, you will need to add a helper method to your user model (`user.rb`) that authenticates the user by email and password:

    ```ruby
    # login by email address
    def self.authenticate(email, password)
      find_by_email(email).try(:authenticate, password)
    end
    ```

11. Now add the following to the `application_controller.rb` file/class along with all the other authentication code (**Note:** You will need to replace the the before_action code with the one below, this code should be below the current "include" and end just above the authenticate method). We are using something called Basic Http Authentication which is provided by rails, that authenticates with email and password. This `/token` endpoint will not be authenticated with the api_key, but rather with email and password. As mentioned before, this endpoint will return the user JSON, which contains the api_key. **Once someone enters their email/password and uses this endpoint to retrieve their api_key, they can then use the api_key to authenticate with all the other endpoints.**

    ```ruby
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :authenticate, except: [:token]

    # A method to handle initial authentication
    def token
      authenticate_username_password || render_unauthorized
    end

    protected

    def authenticate_username_password
      authenticate_or_request_with_http_basic do |email, password|
        user = User.authenticate(email, password)
        if user
          render json: user
        end
      end
    end
    ```

12. After adding this don't forget to add all the token action to the `routes.rb` file. (GET request to `/token` will use the `application#token` action)

13. Now that you have an endpoint in the application controller, you will need to add swagger docs to it as well.

    ```ruby
    swagger_controller :application, "Application Management"

    swagger_api :token do |api|
      summary "Authenticate with email and password to get token"
      param :header, "Authorization", :string, :required, "Email and password in the format of: Basic {Base64.encode64('email:password')}"
    end
    ```

14. **Please understand the following before continuing.** Here's an explanation of the format of how you would interact with the `/token` endpoint, since we will need to do everything the Rails way. Just like with Token auth, the way they intake the email/password is through the `Authorization` header and it needs to be in the format of `Basic {<Base64 encoded 'email:password'>}`. Just encode the string 'email:password' on your own (dont forget the colon between your users email and password), and insert the encoded string into the authorization in the format specified.

    Let's be more concrete on this. Earlier we created the user "jlp@starfleet.org" with password "secret". If we opened rails console and put in `Base64.encode64("jlp@starfleet.org:secret")`, we'd get the encoded email:password combo of `amxwQHN0YXJmbGVldC5vcmc6c2VjcmV0\n`. In this case the full header should be Authorization: `Basic {amxwQHN0YXJmbGVldC5vcmc6c2VjcmV0\n}`. This is what is passed initially so that we can access the API key for our app.

    Running this in Swagger Docs (or using the CURL command as Prof. H did in class), you see the `api_key` for this user (as well as other user info). Copy that key and the use it in the other Swagger Docs with the Authorization header of `Token token=<api_key>` (without the <>)). For all our other requests now, we need to pass this key. Trying running a request in Children without a key or with a bad key and contrast that with proper use of the key.

---

**STOP**: Show a TA that you have the whole ChoreTracker API is authenticated properly with the token endpoint as well.

---

## Part 3 - Versioning

Versioning your API is crucial! Before releasing your public API to the public, you should consider implementing some form of versioning. Versioning breaks your API up into multiple version namespaces, such as `v1` and `v2`, so that you can maintain backwards compatibility for existing clients whenever you introduce breaking changes into your API, simply by incrementing your API version.

In this lab we will be setting up versioning in the following format (i.e. `GET http://[yourUrl]:3000/v1/children/`):

```
http://<domain>/<version>/<route>
```

Let's say you have already released the current version of your API to the public. After a few of months, you already have a bunch of users building apps around your API. Suddenly, you realize a huge improvement that you can make to your API. Just like with the `chore_task_serializer.rb`, you want to make a preview serializer for the child for each task called `chore_child_serializer.rb`. Therefore, you will need to change a param in the `chore_serializer.rb`, namely `child_id` to just a child object. Unfortunately, you realize that if you want to make this huge improvement and release it, it will break a lot of your users' code (since they relied on the fact that the chore serializer to have a `child_id`). This is a perfect time to utilize versioning!!!

1. Since you only have one version of your API, you will need to put all your controllers under the namespace `Api::V1`. We only need to make the changes to the controller and not the models because the only main changes that should happen to an API is in the controllers and serializers. Rearrange all of your controllers into this folder structure:

   ```
   app/controllers/
   .
   |-- api
   |   |-- v1
   |       |-- application_controller.rb
   |       |-- children_controller.rb
   |       |-- chores_controller.rb
   |       |-- tasks_controller.rb
   |       |-- users_controller.rb
   ```

2. Because you have changed the folder structure for all of your controllers, you will also need to update the module naming scheme for each controller (add `module Api::V1`). Follow the pattern below for the `application_controller.rb` and make the necessary changes for all the controllers:

   ```ruby
   module Api::V1
     class ApplicationController < ActionController::API
       # Some Controller Code
       # ...
     end
   end
   ```

3. Now that you have completed all the necessary changes to your controllers, you will need to make similar changes to the serializers. You will need to modify the folder structure in the same way too (using `api/v1/<serializers>`) and adding the `module Api::V1` to all the serializers.

4. After you have properly fixed all the namespaces for the controllers and serializers, we need to fix the same namespace issue with the routes. As mentioned before, we want our routes to be formatted something like this `http://localhost:3000/v1/children/`. All you need to do is add `scope module: 'api' do` and `namespace :v1 do`. This allows the route to be `/v1/children/` instead of `/api/v1/children`, but at the same time be able to find the right namespace of `Api::V1`. (**Note:** If later on, you want the routes to be `/api/v1/children` then all you need to do is to change `scope module: 'api' do` to `namespace :api do`.)

   ```ruby
   Rails.application.routes.draw do
     scope module: 'api' do
       namespace :v1 do
         resources :children
         resources :tasks
         resources :chores
         resources :users

         get :token, controller: 'application'
       end
     end
   end
   ```

5. Make sure you restart your server and run `rails swagger:docs` again so the swagger docs can have the updated routes. Now you should test that the API routes are working, and notice that the routes all have `/v1` in front of them. You can also run `rails routes` to check the routes.

6. All the get requests seem to work properly, but you may have noticed that creating a new instance (POST request) causes an error to show that states `NoMethodError: undefined method 'child_url'`. This is caused by the location param when rendering the newly created object. The way we have it now (for the children controller) is like below:

   ```ruby
   # POST /children
   def create
     @child = Child.new(child_params)

     if @child.save
       render json: @child, status: :created, location: @child
     else
       render json: @child.errors, status: :unprocessable_entity
     end
   end
   ```

   As mentioned before, the location param is something that exists in the headers which tells users of your API the location of where the newly created is. For example, let's say that the id of the newly created child is 1, then the location should be `/v1/children/1`. However, because we changed the namespace, our controllers are still assuming that the location is still at `/children/1`. In order to change it, we need to add `[:v1, @child]`, like below:

   ```ruby
   # POST /children
   def create
     @child = Child.new(child_params)

     if @child.save
       render json: @child, status: :created, location: [:v1, @child]
     else
       render json: @child.errors, status: :unprocessable_entity
     end
   end
   ```

7. Make the necessary changes to all the create actions for all the controllers. Afterward, test out that it works using swagger.

8. Now that you have versioning in place, everything you have up to this point will be called v1. Let's go back to the original scenario that we had regarding the improvement of having a `chore_child_serializer.rb`. In this case, we can just make `v2`, so all users that were using v1, will have the exact version they were expecting, and new users can just begin utilizing the new and improved v2. Later on, users of v1, can slowly transition their application to v2. Versioning basically makes sure that any improvements you make to the API will not break the code that other people have written!

9. Let's begin this improvement by making a `v2` folder in both the controllers and serializers (`/app/controllers/api/v2` and `/app/serializers/api/v2`) and copy all the contents from `v1` into there. Make sure you go through each of the files and change the module name from `Api::V1` to `Api::V2`.

10. Now make the necessary changes to the `chore_serializer.rb` and create a new `chore_child_serializer.rb` that just displays the `:id, :name, :points_earned, :active` of the child. Read the first paragraph of Part 7 if you don't remember what we need to do. To summarize, all you need to do is create a preview JSON serializer for the child in the chore serializer (similar to how we did it for task).

11. You will also need to modify the `routes.rb` file. Under the `scope module: api` make a new namespace called v2 (`namespace :v2`) right underneath v1 and copy paste the same resources and endpoints from v1.

12. Lastly, you will need to make a minor change to the swagger docs initializer located at `/config/initializers/swagger_docs.rb`. Under the registered APIs, after version `1.0`, create a version `2.0` and add the following, which is basically the same thing as version 1.0:

    ```
    "2.0" => {
      # the extension used for the API
      :api_extension_type => :json,
      # the output location where your .json files are written to
      :api_file_path => "public/apidocs",
      # the URL base path to your API (make sure to change this if you are not using localhost:3000)
      :base_path => "http://localhost:3000",
      # if you want to delete all .json files at each generation
      :clean_directory => false,
      # add custom attributes to api-docs
      :attributes => {
        :info => {
          "title" => "Chore Tracker API",
          "description" => "Uses swagger ui and docs to document the ChoreTracker API"
        }
      }
    }
    ```

13. Now you can run `rails swagger:docs` again and test out that `v2/chores` displays the child and not just the child_id. Swagger docs might show up a bit weird since there are 2 versions running right now. There should be 2 sets of endpoints displaying, but make sure you test this out with the v2 version of the children endpoints.

---

**STOP**: Show a TA that you have the whole ChoreTracker API versioned properly with a v1 and v2.

---

## Part 4 - Rack Attack (_on_your_own_)

1. When developing an API in the real world, there are more things that you need to take care of before you put your application in production. One major thing is adding a layer of middleware to protect against malicious attacks. Middleware is everything that exists between your application server (what actually hosts your web app) and the actual Rails application. So what happens when you have a user that just keeps on spamming your API and slowing down your service? Well, there are ways to prevent that through your middleware by throttling those users (basically telling them to back off a little bit before hitting your server again). One such middleware is [Rack::Attack](https://github.com/kickstarter/rack-attack), which was created by the good folks at [Kickstarter](https://www.kickstarter.com/)

2. First, you need to include Rack Attack in your gem file and run `bundle install`.

   ```ruby
   gem 'rack-attack'
   ```

3. Then you need to setup an initializer in order for Rack Attack to work. All you need to do is go to `config/initializers/` and create a new file called `rack_attack.rb` and put the following in the file. All this means is that you are throttling (or limiting) hits from users by their IP addresses and you are setting the limit to 3 hits within 10 seconds. Usually that number should be a lot higher, but we kept it low just for testing purposes.

   ```ruby
   class Rack::Attack
     Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

     throttle('req/ip', limit: 3, period: 10) do |req|
       req.ip
     end
   end
   ```

4. Before you go on you will also need to add the following to your `config/application.rb` file.

   ```ruby
   module ChoreTrackerAPI
     class Application < Rails::Application
       # Other code
       # ...

       config.middleware.use Rack::Attack
     end
   end
   ```

5. Now after restarting the server (since we've updated the application.rb file and added an initializer) if you use Swagger Docs or Curl to hit your RESTful API 4 times quickly! You will find that on the 4th try you will be rejected with a Retry Later message. This may not look very consistent with the rest of the JSON response, so we need to change how the error message is displayed. To do so, go back to the initializer (`config/initializers/rack_attack.rb`) and change the code to the following. We will not go through exactly what the code means, but it generally means that it will respond instead with a JSON object with the 429 error code.

   ```ruby
   class Rack::Attack
     Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

     throttle('req/ip', limit: 3, period: 10) do |req|
       req.ip
     end

     self.throttled_response = ->(env) {
       retry_after = (env['rack.attack.match_data'] || {})[:period]
       [
         429,
         {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
         [{error: "Throttle limit reached. Retry later."}.to_json]
       ]
     }
   end
   ```

6. Now your application will be protected against any user/from an IP address from spamming your API and slowing down your server!
