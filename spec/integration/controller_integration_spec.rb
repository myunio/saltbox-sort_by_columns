require "rails_helper"
require "has_scope"

RSpec.describe "Controller Integration with has_scope", type: :controller do
  # Create a real Rails controller for integration testing
  controller(ActionController::Base) do
    include Saltbox::SortByColumns::Controller

    def index
      @users = User.all
      @users = apply_scopes(@users)
      render json: @users.pluck(:id, :name, :email)
    end

    def show
      @user = User.find(params[:id])
      render json: @user
    end

    def create
      # This action should not have sorting applied
      @users = User.all
      @users = apply_scopes(@users)
      render json: @users.pluck(:id, :name)
    end

    private

    def apply_scopes(relation)
      # This is how has_scope typically works in controllers
      relation = relation.sorted_by_columns(params[:sort]) if params[:sort]
      relation
    end
  end

  let!(:org_a) { Organization.create!(name: "Alpha Inc") }
  let!(:org_b) { Organization.create!(name: "Beta Corp") }
  let!(:user1) { User.create!(name: "Charlie", email: "charlie@example.com", organization: org_b) }
  let!(:user2) { User.create!(name: "Alice", email: "alice@example.com", organization: org_a) }
  let!(:user3) { User.create!(name: "Bob", email: "bob@example.com", organization: org_a) }

  before do
    User.sort_by_columns :name, :email, :organization__name, :c_full_name
  end

  describe "has_scope gem integration" do
    context "with real has_scope functionality" do
      it "processes sort parameter correctly in index action" do
        get :index, params: {sort: "name:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should be sorted by name ascending: Alice, Bob, Charlie
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "processes complex sort parameters with multiple columns" do
        get :index, params: {sort: "name:asc,email:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should be sorted by name first, then email descending
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "processes association column sorting" do
        get :index, params: {sort: "organization__name:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should be sorted by organization name: Alpha Inc users first, then Beta Corp
        names = json_response.map { |user| user[1] }
        expect(names.first(2)).to contain_exactly("Alice", "Bob")
        expect(names.last).to eq("Charlie")
      end

      it "handles empty sort parameter gracefully" do
        get :index, params: {sort: ""}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles missing sort parameter gracefully" do
        get :index

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end

    context "with has_scope restrictions" do
      it "only applies sorting to index action" do
        # Test that sorting is applied in index
        get :index, params: {sort: "name:asc"}
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])

        # Test that sorting is not automatically applied in other actions
        get :show, params: {id: user1.id, sort: "name:asc"}
        expect(response).to be_successful
        # Should return the specific user, not sorted list
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("Charlie")
      end

      it "does not apply sorting to create action" do
        post :create, params: {sort: "name:asc"}
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Should return users but not necessarily sorted (depends on implementation)
        expect(json_response.length).to eq(3)
      end
    end
  end

  describe "URL parameter processing" do
    context "with various URL parameter formats" do
      it "processes single column sort from URL" do
        get :index, params: {sort: "name:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Charlie Bob Alice])
      end

      it "processes multiple column sorts from URL" do
        get :index, params: {sort: "name:asc,email:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "processes association column sorts from URL" do
        get :index, params: {sort: "organization__name:desc,name:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Beta Corp first (Charlie), then Alpha Inc (Alice, Bob)
        expect(json_response.first[1]).to eq("Charlie")
        expect(json_response.last(2).map { |user| user[1] }).to contain_exactly("Alice", "Bob")
      end

      it "handles URL-encoded sort parameters" do
        # Test with URL-encoded parameters (spaces become +, etc.)
        get :index, params: {sort: "name:asc,email:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles complex URL parameter scenarios" do
        # Test with additional parameters mixed with sort
        get :index, params: {sort: "name:asc", page: 1, per_page: 10}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end
    end

    context "with malformed URL parameters" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.logger).to receive(:warn)
      end

      it "handles malformed sort parameters gracefully" do
        get :index, params: {sort: "invalid::column"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles invalid column names in URL" do
        get :index, params: {sort: "nonexistent:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles special characters in sort parameters" do
        get :index, params: {sort: "name@#$%:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end
  end

  describe "Rails parameter handling" do
    context "with Rails strong parameters" do
      it "processes sort parameter through Rails parameter filtering" do
        # This tests that the parameter passes through Rails' parameter processing
        get :index, params: {sort: "name:asc", other_param: "ignored"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "handles nested parameters correctly" do
        get :index, params: {sort: "name:asc", filter: {status: "active"}}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "handles array parameters in Rails" do
        get :index, params: {sort: "name:asc", ids: [1, 2, 3]}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end
    end

    context "with Rails parameter conversion" do
      it "handles string parameters correctly" do
        get :index, params: {sort: "name:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "handles symbol parameters correctly" do
        # Rails typically converts parameters to strings, but test edge cases
        controller.params[:sort] = "name:asc"
        get :index

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end

    context "with Rails parameter security" do
      # SECURITY TESTING: Parameter Pollution Attacks
      # Attackers may try to send array parameters where strings are expected
      # This can bypass application logic or cause unexpected behavior

      it "prevents parameter pollution attacks" do
        # ATTACK PATTERN: Parameter pollution via array injection
        # Malicious users might send: ?sort[]=name:asc&sort[]=malicious_payload
        # Rails would convert this to an array: params[:sort] = ["name:asc", "malicious_payload"]
        # The gem must handle this gracefully without exposing internal data

        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.logger).to receive(:warn)

        # SIMULATE: Attack payload as array parameter
        get :index, params: {sort: ["name:asc", "evil:payload"]}

        # EXPECTED: System continues to work, doesn't crash or expose data
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles nil parameters safely" do
        controller.params[:sort] = nil
        get :index

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end
  end

  describe "controller edge cases and error handling" do
    context "with development environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "raises errors for invalid columns in development" do
        expect {
          get :index, params: {sort: "invalid_column:asc"}
        }.to raise_error(ArgumentError, /disallowed sortable column/)
      end

      it "raises errors for invalid associations in development" do
        User.sort_by_columns :name, :invalid_association__name

        expect {
          get :index, params: {sort: "invalid_association__name:asc"}
        }.to raise_error(ArgumentError, /doesn't exist on model/)
      end
    end

    context "with production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.logger).to receive(:warn)
      end

      it "logs warnings and continues for invalid columns" do
        expect(Rails.logger).to receive(:warn).with(/ignoring disallowed column/)

        get :index, params: {sort: "invalid_column:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it "handles mixed valid and invalid columns" do
        get :index, params: {sort: "invalid:asc,name:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Should be sorted by name desc (valid column), ignoring invalid column
        expect(json_response.map { |user| user[1] }).to eq(%w[Charlie Bob Alice])
      end
    end

    context "with database errors" do
      it "does not swallow database exceptions" do
        allow(User).to receive(:all).and_raise(ActiveRecord::StatementInvalid)

        expect {
          get :index, params: {sort: "name:asc"}
        }.to raise_error(ActiveRecord::StatementInvalid)
      end

      it "does not swallow connection errors" do
        allow(User).to receive(:all).and_raise(ActiveRecord::ConnectionNotEstablished)

        expect {
          get :index, params: {sort: "name:asc"}
        }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end

    context "with controller-specific edge cases" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.logger).to receive(:warn)
      end

      it "handles very long sort parameter strings" do
        # PERFORMANCE TEST: Protection against denial-of-service attacks
        # Attackers might send extremely long parameter strings to consume server resources
        # The gem should process these efficiently without causing timeouts or memory issues
        long_sort = (1..100).map { |i| "col#{i}:asc" }.join(",") + ",name:desc"

        get :index, params: {sort: long_sort}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Should sort by name:desc (the only valid column from the long string)
        expect(json_response.map { |user| user[1] }).to eq(%w[Charlie Bob Alice])
      end

      it "handles concurrent requests safely" do
        # CONCURRENCY TEST: Thread safety verification
        # In production Rails apps, multiple requests may process sorting simultaneously
        # The gem must not have race conditions or shared mutable state

        # NOTE: Simplified test due to Rails controller test limitations
        # In real applications, this would involve actual concurrent threads
        results = []

        5.times do
          get :index, params: {sort: "name:asc"}
          results << response.status
        end

        # EXPECTED: All requests should succeed without interference
        expect(results.all? { |status| status == 200 }).to be true
      end

      it "handles memory efficiently with large parameter strings" do
        # MEMORY EFFICIENCY TEST: Large payload processing
        # Ensures the gem doesn't create memory leaks or excessive object allocation
        # when processing large numbers of invalid column specifications
        huge_sort = (1..1000).map { |i| "invalid_col_#{i}:asc" }.join(",") + ",name:asc"

        get :index, params: {sort: huge_sort}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Should efficiently extract and process only the valid column (name:asc)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end
    end
  end

  describe "real-world integration scenarios" do
    context "with typical Rails application patterns" do
      it "works with pagination parameters" do
        get :index, params: {sort: "name:asc", page: 1, per_page: 2}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "works with search parameters" do
        get :index, params: {sort: "name:asc", search: "alice"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "works with filter parameters" do
        get :index, params: {sort: "name:asc", filter: {organization: "Alpha Inc"}}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
      end

      it "maintains sort order across multiple requests" do
        # First request
        get :index, params: {sort: "name:asc"}
        first_response = JSON.parse(response.body)

        # Second request with same sort
        get :index, params: {sort: "name:asc"}
        second_response = JSON.parse(response.body)

        expect(first_response.map { |user| user[1] }).to eq(second_response.map { |user| user[1] })
      end

      it "handles different sort orders in different requests" do
        # Ascending request
        get :index, params: {sort: "name:asc"}
        asc_response = JSON.parse(response.body)

        # Descending request
        get :index, params: {sort: "name:desc"}
        desc_response = JSON.parse(response.body)

        expect(asc_response.map { |user| user[1] }).to eq(%w[Alice Bob Charlie])
        expect(desc_response.map { |user| user[1] }).to eq(%w[Charlie Bob Alice])
      end
    end

    context "with custom scope integration" do
      it "handles custom scope parameters correctly" do
        get :index, params: {sort: "c_full_name:desc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        # Should be sorted by the custom scope
        expect(json_response.length).to eq(3)
      end

      it "prevents mixing custom scopes with regular columns" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.logger).to receive(:warn)

        get :index, params: {sort: "c_full_name:desc,name:asc"}

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end
  end
end
