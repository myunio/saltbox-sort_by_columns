# Real-World Examples for Saltbox::SortByColumns

This document provides comprehensive, real-world examples of how to integrate and use the Saltbox::SortByColumns gem in your Rails applications.

## Table of Contents

1. [E-commerce Product Catalog](#e-commerce-product-catalog)
2. [User Management System](#user-management-system)
3. [Project Management Dashboard](#project-management-dashboard)
4. [Blog Platform](#blog-platform)
5. [Customer Support System](#customer-support-system)
6. [API Implementation Patterns](#api-implementation-patterns)
7. [Frontend Integration](#frontend-integration)

## E-commerce Product Catalog

### Models

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  include Saltbox::SortByColumns::Model

  belongs_to :category
  belongs_to :brand
  has_many :reviews
  has_many :order_items

  # Standard columns, associations, and custom scopes
  sort_by_columns :name, :price, :created_at, :updated_at,
                     :category__name, :brand__name, 
                     :c_popularity, :c_rating, :c_total_sales

  # Custom scope: Sort by popularity (view count + order count)
  scope :sorted_by_popularity, ->(direction) {
    left_joins(:order_items)
      .group('products.id')
      .order("(products.view_count + COALESCE(COUNT(order_items.id), 0)) #{direction}")
  }

  # Custom scope: Sort by average rating
  scope :sorted_by_rating, ->(direction) {
    left_joins(:reviews)
      .group('products.id')
      .order("COALESCE(AVG(reviews.rating), 0) #{direction}")
  }

  # Custom scope: Sort by total sales volume
  scope :sorted_by_total_sales, ->(direction) {
    left_joins(:order_items)
      .group('products.id')
      .order("COALESCE(SUM(order_items.quantity * order_items.price), 0) #{direction}")
  }
end

# app/models/category.rb
class Category < ApplicationRecord
  has_many :products
end

# app/models/brand.rb
class Brand < ApplicationRecord
  has_many :products
end
```

### Controller

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  include Saltbox::SortByColumns::Controller

  def index
    @products = apply_scopes(Product.includes(:category, :brand))
                  .where(active: true)
                  .page(params[:page])
                  .per(params[:per_page] || 12)

    # Add search functionality
    if params[:search].present?
      @products = @products.where("name ILIKE ?", "%#{params[:search]}%")
    end

    # Add category filtering
    if params[:category_id].present?
      @products = @products.where(category_id: params[:category_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: @products }
    end
  end
end
```

### API Usage Examples

```bash
# Basic sorting
GET /products?sort=name:asc
GET /products?sort=price:desc

# Sort by category name
GET /products?sort=category__name:asc

# Sort by brand name
GET /products?sort=brand__name:desc

# Sort by custom popularity score
GET /products?sort=c_popularity:desc

# Sort by average rating
GET /products?sort=c_rating:desc

# Sort by total sales volume
GET /products?sort=c_total_sales:desc

# Multiple column sorting
GET /products?sort=category__name:asc,price:desc

# Combined with search and filtering
GET /products?sort=c_popularity:desc&search=laptop&category_id=1&page=2
```

### View Implementation

```erb
<!-- app/views/products/index.html.erb -->
<div class="products-header">
  <h1>Products</h1>
  
  <div class="sorting-controls">
    <%= link_to "Name A-Z", products_path(sort: "name:asc"), 
        class: "sort-link #{active_sort_class('name:asc')}" %>
    <%= link_to "Name Z-A", products_path(sort: "name:desc"), 
        class: "sort-link #{active_sort_class('name:desc')}" %>
    <%= link_to "Price Low-High", products_path(sort: "price:asc"), 
        class: "sort-link #{active_sort_class('price:asc')}" %>
    <%= link_to "Price High-Low", products_path(sort: "price:desc"), 
        class: "sort-link #{active_sort_class('price:desc')}" %>
    <%= link_to "Most Popular", products_path(sort: "c_popularity:desc"), 
        class: "sort-link #{active_sort_class('c_popularity:desc')}" %>
    <%= link_to "Best Rated", products_path(sort: "c_rating:desc"), 
        class: "sort-link #{active_sort_class('c_rating:desc')}" %>
  </div>
</div>

<div class="products-grid">
  <% @products.each do |product| %>
    <div class="product-card">
      <h3><%= product.name %></h3>
      <p>Category: <%= product.category.name %></p>
      <p>Brand: <%= product.brand.name %></p>
      <p>Price: $<%= product.price %></p>
    </div>
  <% end %>
</div>

<%= paginate @products %>
```

### Helper Methods

```ruby
# app/helpers/products_helper.rb
module ProductsHelper
  def active_sort_class(sort_param)
    params[:sort] == sort_param ? 'active' : ''
  end

  def sort_link(text, sort_param, options = {})
    css_class = "sort-link"
    css_class += " active" if params[:sort] == sort_param
    css_class += " #{options[:class]}" if options[:class]

    link_to text, products_path(params.permit(:search, :category_id, :page).merge(sort: sort_param)), 
            class: css_class
  end
end
```

## User Management System

### Models

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Saltbox::SortByColumns::Model

  belongs_to :organization, optional: true
  belongs_to :role
  has_many :tickets
  has_many :comments

  sort_by_columns :name, :email, :created_at, :last_sign_in_at,
                     :organization__name, :role__name,
                     :c_activity_score, :c_ticket_count

  # Custom scope: Activity score based on recent actions
  scope :sorted_by_activity_score, ->(direction) {
    left_joins(:comments)
      .where(comments: { created_at: 30.days.ago.. })
      .group('users.id')
      .order("COUNT(comments.id) #{direction}")
  }

  # Custom scope: Total ticket count
  scope :sorted_by_ticket_count, ->(direction) {
    left_joins(:tickets)
      .group('users.id')
      .order("COUNT(tickets.id) #{direction}")
  }
end

# app/models/organization.rb
class Organization < ApplicationRecord
  has_many :users
end

# app/models/role.rb
class Role < ApplicationRecord
  has_many :users
end
```

### Admin Controller

```ruby
# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  include Saltbox::SortByColumns::Controller

  before_action :authenticate_admin!

  def index
    @users = apply_scopes(User.includes(:organization, :role))

    # Filter by organization
    if params[:organization_id].present?
      @users = @users.where(organization_id: params[:organization_id])
    end

    # Filter by role
    if params[:role_id].present?
      @users = @users.where(role_id: params[:role_id])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @users = @users.where(active: true)
    when 'inactive'
      @users = @users.where(active: false)
    end

    @users = @users.page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@users), filename: "users-#{Date.current}.csv" }
    end
  end

  private

  def generate_csv(users)
    CSV.generate(headers: true) do |csv|
      csv << ['Name', 'Email', 'Organization', 'Role', 'Created At', 'Last Sign In']
      users.each do |user|
        csv << [
          user.name,
          user.email,
          user.organization&.name,
          user.role.name,
          user.created_at,
          user.last_sign_in_at
        ]
      end
    end
  end
end
```

### API Examples

```bash
# Sort by name
GET /admin/users?sort=name:asc

# Sort by organization name
GET /admin/users?sort=organization__name:asc

# Sort by role name
GET /admin/users?sort=role__name:desc

# Sort by recent activity
GET /admin/users?sort=c_activity_score:desc

# Sort by ticket count
GET /admin/users?sort=c_ticket_count:desc

# Combined filtering and sorting
GET /admin/users?sort=created_at:desc&organization_id=5&status=active
```

## Project Management Dashboard

### Models

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  include Saltbox::SortByColumns::Model

  belongs_to :owner, class_name: 'User'
  has_many :tasks
  has_many :project_members
  has_many :members, through: :project_members, source: :user

  sort_by_columns :name, :created_at, :due_date, :status,
                     :owner__name, :c_completion_rate, :c_task_count, :c_overdue_count

  # Custom scope: Completion rate based on completed tasks
  scope :sorted_by_completion_rate, ->(direction) {
    left_joins(:tasks)
      .group('projects.id')
      .order("
        CASE 
          WHEN COUNT(tasks.id) = 0 THEN 0
          ELSE (COUNT(CASE WHEN tasks.status = 'completed' THEN 1 END) * 100.0 / COUNT(tasks.id))
        END #{direction}
      ")
  }

  # Custom scope: Total task count
  scope :sorted_by_task_count, ->(direction) {
    left_joins(:tasks)
      .group('projects.id')
      .order("COUNT(tasks.id) #{direction}")
  }

  # Custom scope: Overdue task count
  scope :sorted_by_overdue_count, ->(direction) {
    left_joins(:tasks)
      .group('projects.id')
      .order("COUNT(CASE WHEN tasks.due_date < CURRENT_DATE AND tasks.status != 'completed' THEN 1 END) #{direction}")
  }
end

# app/models/task.rb
class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee, class_name: 'User', optional: true
end
```

### Dashboard Controller

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  include Saltbox::SortByColumns::Controller

  before_action :authenticate_user!

  def projects
    @projects = apply_scopes(current_user.accessible_projects.includes(:owner))

    # Filter by status
    if params[:status].present?
      @projects = @projects.where(status: params[:status])
    end

    # Filter by due date
    case params[:due_date_filter]
    when 'overdue'
      @projects = @projects.where('due_date < ?', Date.current)
    when 'this_week'
      @projects = @projects.where(due_date: Date.current.beginning_of_week..Date.current.end_of_week)
    when 'next_week'
      @projects = @projects.where(due_date: 1.week.from_now.beginning_of_week..1.week.from_now.end_of_week)
    end

    @projects = @projects.page(params[:page]).per(10)
  end
end
```

### View with Dynamic Sorting

```erb
<!-- app/views/dashboard/projects.html.erb -->
<div class="projects-dashboard">
  <div class="dashboard-header">
    <h2>My Projects</h2>
    
    <div class="sort-dropdown">
      <%= form_with url: dashboard_projects_path, method: :get, local: true, class: "sort-form" do |f| %>
        <%= f.select :sort, options_for_select([
          ['Name A-Z', 'name:asc'],
          ['Name Z-A', 'name:desc'],
          ['Newest First', 'created_at:desc'],
          ['Oldest First', 'created_at:asc'],
          ['Due Date (Earliest)', 'due_date:asc'],
          ['Due Date (Latest)', 'due_date:desc'],
          ['Most Complete', 'c_completion_rate:desc'],
          ['Most Tasks', 'c_task_count:desc'],
          ['Most Overdue', 'c_overdue_count:desc']
        ], params[:sort]), 
        { include_blank: 'Sort by...' }, 
        { onchange: 'this.form.submit();', class: 'form-select' } %>
        
        <%= hidden_field_tag :status, params[:status] %>
        <%= hidden_field_tag :due_date_filter, params[:due_date_filter] %>
      <% end %>
    </div>
  </div>

  <div class="filters">
    <%= link_to 'All', dashboard_projects_path(sort: params[:sort]), 
        class: "filter-link #{params[:status].blank? ? 'active' : ''}" %>
    <%= link_to 'Active', dashboard_projects_path(sort: params[:sort], status: 'active'), 
        class: "filter-link #{params[:status] == 'active' ? 'active' : ''}" %>
    <%= link_to 'Completed', dashboard_projects_path(sort: params[:sort], status: 'completed'), 
        class: "filter-link #{params[:status] == 'completed' ? 'active' : ''}" %>
  </div>

  <div class="projects-grid">
    <% @projects.each do |project| %>
      <div class="project-card">
        <h3><%= link_to project.name, project_path(project) %></h3>
        <p>Owner: <%= project.owner.name %></p>
        <p>Status: <%= project.status.humanize %></p>
        <p>Due: <%= project.due_date&.strftime('%B %d, %Y') || 'No due date' %></p>
        
        <div class="progress-bar">
          <div class="progress-fill" style="width: <%= project.completion_percentage %>%"></div>
        </div>
        <small><%= project.completion_percentage %>% complete</small>
      </div>
    <% end %>
  </div>

  <%= paginate @projects %>
</div>
```

## Blog Platform

### Models

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Saltbox::SortByColumns::Model

  belongs_to :author, class_name: 'User'
  belongs_to :category
  has_many :comments
  has_many :post_tags
  has_many :tags, through: :post_tags

  sort_by_columns :title, :published_at, :created_at, :view_count,
                     :author__name, :category__name,
                     :c_comment_count, :c_engagement_score

  scope :published, -> { where(published: true) }

  # Custom scope: Comment count
  scope :sorted_by_comment_count, ->(direction) {
    left_joins(:comments)
      .group('posts.id')
      .order("COUNT(comments.id) #{direction}")
  }

  # Custom scope: Engagement score (views + comments * 10)
  scope :sorted_by_engagement_score, ->(direction) {
    left_joins(:comments)
      .group('posts.id')
      .order("(posts.view_count + COUNT(comments.id) * 10) #{direction}")
  }
end
```

### Public Blog Controller

```ruby
# app/controllers/blog_controller.rb
class BlogController < ApplicationController
  include Saltbox::SortByColumns::Controller

  def index
    @posts = apply_scopes(Post.published.includes(:author, :category))

    # Category filtering
    if params[:category_id].present?
      @posts = @posts.where(category_id: params[:category_id])
    end

    # Tag filtering
    if params[:tag].present?
      @posts = @posts.joins(:tags).where(tags: { slug: params[:tag] })
    end

    # Search
    if params[:search].present?
      @posts = @posts.where("title ILIKE ? OR excerpt ILIKE ?", 
                           "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @posts = @posts.page(params[:page]).per(10)

    # Increment view counts (async job recommended for production)
    @posts.each { |post| post.increment!(:view_count) }
  end

  def show
    @post = Post.published.find(params[:id])
    @post.increment!(:view_count)
  end
end
```

### Admin Blog Controller

```ruby
# app/controllers/admin/posts_controller.rb
class Admin::PostsController < ApplicationController
  include Saltbox::SortByColumns::Controller

  before_action :authenticate_admin!

  def index
    @posts = apply_scopes(Post.includes(:author, :category))

    # Status filtering
    case params[:status]
    when 'published'
      @posts = @posts.where(published: true)
    when 'draft'
      @posts = @posts.where(published: false)
    end

    # Author filtering (if admin wants to filter by specific author)
    if params[:author_id].present?
      @posts = @posts.where(author_id: params[:author_id])
    end

    @posts = @posts.page(params[:page]).per(20)
  end
end
```

### API Examples

```bash
# Public blog sorting
GET /blog?sort=published_at:desc           # Latest posts
GET /blog?sort=c_engagement_score:desc     # Most engaging posts
GET /blog?sort=view_count:desc             # Most viewed posts
GET /blog?sort=c_comment_count:desc        # Most commented posts
GET /blog?sort=title:asc                   # Alphabetical

# With filtering
GET /blog?sort=published_at:desc&category_id=3
GET /blog?sort=c_engagement_score:desc&tag=rails
GET /blog?sort=view_count:desc&search=ruby

# Admin sorting
GET /admin/posts?sort=created_at:desc      # Latest created
GET /admin/posts?sort=author__name:asc     # By author name
GET /admin/posts?sort=category__name:asc   # By category
GET /admin/posts?sort=published_at:desc&status=published
```

## Customer Support System

### Models

```ruby
# app/models/ticket.rb
class Ticket < ApplicationRecord
  include Saltbox::SortByColumns::Model

  belongs_to :customer, class_name: 'User'
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :priority
  has_many :ticket_comments

  sort_by_columns :subject, :created_at, :updated_at, :status, :due_date,
                     :customer__name, :customer__email, :assignee__name, :priority__name,
                     :c_response_time, :c_last_activity

  # Custom scope: Average response time
  scope :sorted_by_response_time, ->(direction) {
    joins(:ticket_comments)
      .where(ticket_comments: { comment_type: 'response' })
      .group('tickets.id')
      .order("AVG(EXTRACT(EPOCH FROM (ticket_comments.created_at - tickets.created_at))) #{direction}")
  }

  # Custom scope: Last activity (most recent comment or update)
  scope :sorted_by_last_activity, ->(direction) {
    left_joins(:ticket_comments)
      .group('tickets.id')
      .order("GREATEST(tickets.updated_at, MAX(ticket_comments.created_at)) #{direction}")
  }
end
```

### Support Dashboard Controller

```ruby
# app/controllers/support/tickets_controller.rb
class Support::TicketsController < ApplicationController
  include Saltbox::SortByColumns::Controller

  before_action :authenticate_support_agent!

  def index
    @tickets = apply_scopes(Ticket.includes(:customer, :assignee, :priority))

    # Queue filtering
    case params[:queue]
    when 'my_tickets'
      @tickets = @tickets.where(assignee: current_user)
    when 'unassigned'
      @tickets = @tickets.where(assignee: nil)
    when 'escalated'
      @tickets = @tickets.joins(:priority).where(priorities: { level: 'high' })
    end

    # Status filtering
    if params[:status].present?
      @tickets = @tickets.where(status: params[:status])
    end

    # Priority filtering
    if params[:priority_id].present?
      @tickets = @tickets.where(priority_id: params[:priority_id])
    end

    # Overdue tickets
    if params[:overdue] == 'true'
      @tickets = @tickets.where('due_date < ?', Time.current)
    end

    @tickets = @tickets.page(params[:page]).per(25)
  end
end
```

### Support Dashboard View

```erb
<!-- app/views/support/tickets/index.html.erb -->
<div class="support-dashboard">
  <div class="dashboard-header">
    <h1>Support Tickets</h1>
    
    <div class="quick-actions">
      <%= link_to "New Ticket", new_support_ticket_path, class: "btn btn-primary" %>
    </div>
  </div>

  <div class="filters-row">
    <div class="queue-filters">
      <%= link_to "All Tickets", support_tickets_path(sort: params[:sort]), 
          class: "filter-btn #{params[:queue].blank? ? 'active' : ''}" %>
      <%= link_to "My Tickets", support_tickets_path(sort: params[:sort], queue: 'my_tickets'), 
          class: "filter-btn #{params[:queue] == 'my_tickets' ? 'active' : ''}" %>
      <%= link_to "Unassigned", support_tickets_path(sort: params[:sort], queue: 'unassigned'), 
          class: "filter-btn #{params[:queue] == 'unassigned' ? 'active' : ''}" %>
      <%= link_to "Escalated", support_tickets_path(sort: params[:sort], queue: 'escalated'), 
          class: "filter-btn #{params[:queue] == 'escalated' ? 'active' : ''}" %>
    </div>

    <div class="sort-controls">
      <%= form_with url: support_tickets_path, method: :get, local: true, class: "inline-form" do |f| %>
        <%= f.select :sort, options_for_select([
          ['Newest First', 'created_at:desc'],
          ['Oldest First', 'created_at:asc'],
          ['Recently Updated', 'c_last_activity:desc'],
          ['Due Date (Urgent)', 'due_date:asc'],
          ['Priority (High to Low)', 'priority__name:desc'],
          ['Customer Name', 'customer__name:asc'],
          ['Assignee Name', 'assignee__name:asc'],
          ['Fastest Response', 'c_response_time:asc']
        ], params[:sort]), 
        { prompt: 'Sort by...' }, 
        { onchange: 'this.form.submit();' } %>
        
        <%= hidden_field_tag :queue, params[:queue] %>
        <%= hidden_field_tag :status, params[:status] %>
        <%= hidden_field_tag :priority_id, params[:priority_id] %>
      <% end %>
    </div>
  </div>

  <div class="tickets-table">
    <table>
      <thead>
        <tr>
          <th>Subject</th>
          <th>Customer</th>
          <th>Assignee</th>
          <th>Priority</th>
          <th>Status</th>
          <th>Created</th>
          <th>Due Date</th>
        </tr>
      </thead>
      <tbody>
        <% @tickets.each do |ticket| %>
          <tr class="ticket-row priority-<%= ticket.priority.level %>">
            <td><%= link_to ticket.subject, support_ticket_path(ticket) %></td>
            <td><%= ticket.customer.name %></td>
            <td><%= ticket.assignee&.name || "Unassigned" %></td>
            <td><%= ticket.priority.name %></td>
            <td><span class="status-badge status-<%= ticket.status %>"><%= ticket.status.humanize %></span></td>
            <td><%= time_ago_in_words(ticket.created_at) %> ago</td>
            <td class="<%= 'overdue' if ticket.due_date && ticket.due_date < Time.current %>">
              <%= ticket.due_date&.strftime('%m/%d/%Y') || '-' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <%= paginate @tickets %>
</div>
```

## API Implementation Patterns

### RESTful API Controller

```ruby
# app/controllers/api/v1/products_controller.rb
class Api::V1::ProductsController < Api::V1::BaseController
  include Saltbox::SortByColumns::Controller

  def index
    @products = apply_scopes(Product.includes(:category, :brand))
                  .where(active: true)

    # Apply additional filtering from query parameters
    @products = apply_filters(@products)

    # Pagination
    @products = @products.page(params[:page]).per(params[:per_page] || 20)

    render json: {
      products: @products.map { |product| product_json(product) },
      pagination: pagination_meta(@products),
      sorting: {
        current: params[:sort],
        available: Product.column_sortable_allowed_fields.map(&:to_s)
      }
    }
  end

  private

  def apply_filters(products)
    products = products.where(category_id: params[:category_id]) if params[:category_id].present?
    products = products.where(brand_id: params[:brand_id]) if params[:brand_id].present?
    products = products.where('price >= ?', params[:min_price]) if params[:min_price].present?
    products = products.where('price <= ?', params[:max_price]) if params[:max_price].present?
    
    if params[:search].present?
      products = products.where("name ILIKE ? OR description ILIKE ?", 
                               "%#{params[:search]}%", "%#{params[:search]}%")
    end

    products
  end

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      price: product.price,
      category: { id: product.category.id, name: product.category.name },
      brand: { id: product.brand.id, name: product.brand.name },
      created_at: product.created_at.iso8601
    }
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
```

### GraphQL Integration

```ruby
# app/graphql/types/product_type.rb
module Types
  class ProductType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :price, Float, null: false
    field :category, Types::CategoryType, null: false
    field :brand, Types::BrandType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end

# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    field :products, [Types::ProductType], null: false do
      argument :sort, String, required: false
      argument :search, String, required: false
      argument :category_id, ID, required: false
      argument :page, Integer, required: false
      argument :per_page, Integer, required: false
    end

    def products(sort: nil, search: nil, category_id: nil, page: 1, per_page: 20)
      products = Product.includes(:category, :brand).where(active: true)

      # Apply sorting using the gem
      if sort.present?
        products = products.sorted_by_columns(sort)
      end

      # Apply filters
      products = products.where(category_id: category_id) if category_id.present?
      if search.present?
        products = products.where("name ILIKE ? OR description ILIKE ?", 
                                 "%#{search}%", "%#{search}%")
      end

      # Pagination
      products.page(page).per(per_page)
    end
  end
end
```

### API Error Handling

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  rescue_from ArgumentError do |exception|
    # Handle sorting errors in API responses
    if exception.message.include?("Column") && exception.message.include?("not found")
      render json: {
        error: "Invalid sort parameter",
        message: exception.message,
        available_sort_fields: current_model_class&.column_sortable_allowed_fields&.map(&:to_s)
      }, status: :bad_request
    else
      render json: { error: "Bad request", message: exception.message }, status: :bad_request
    end
  end

  private

  def current_model_class
    # Determine model class from controller name
    controller_name.classify.constantize
  rescue NameError
    nil
  end
end
```

## Frontend Integration

### JavaScript/React Integration

```javascript
// components/ProductList.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [sortBy, setSortBy] = useState('name:asc');
  const [pagination, setPagination] = useState({});

  const sortOptions = [
    { value: 'name:asc', label: 'Name A-Z' },
    { value: 'name:desc', label: 'Name Z-A' },
    { value: 'price:asc', label: 'Price Low-High' },
    { value: 'price:desc', label: 'Price High-Low' },
    { value: 'category__name:asc', label: 'Category A-Z' },
    { value: 'c_popularity:desc', label: 'Most Popular' },
    { value: 'c_rating:desc', label: 'Best Rated' },
    { value: 'created_at:desc', label: 'Newest First' }
  ];

  useEffect(() => {
    fetchProducts();
  }, [sortBy]);

  const fetchProducts = async (page = 1) => {
    setLoading(true);
    try {
      const response = await axios.get('/api/v1/products', {
        params: {
          sort: sortBy,
          page: page,
          per_page: 12
        }
      });
      
      setProducts(response.data.products);
      setPagination(response.data.pagination);
    } catch (error) {
      console.error('Error fetching products:', error);
      // Handle sorting errors gracefully
      if (error.response?.status === 400 && error.response.data?.error === 'Invalid sort parameter') {
        setSortBy('name:asc'); // Reset to default
        alert('Invalid sort option. Resetting to default.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSortChange = (newSortBy) => {
    setSortBy(newSortBy);
  };

  return (
    <div className="product-list">
      <div className="controls">
        <select 
          value={sortBy} 
          onChange={(e) => handleSortChange(e.target.value)}
          className="sort-select"
        >
          {sortOptions.map(option => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <div>Loading...</div>
      ) : (
        <>
          <div className="products-grid">
            {products.map(product => (
              <div key={product.id} className="product-card">
                <h3>{product.name}</h3>
                <p>${product.price}</p>
                <p>Category: {product.category.name}</p>
                <p>Brand: {product.brand.name}</p>
              </div>
            ))}
          </div>

          <div className="pagination">
            {Array.from({ length: pagination.total_pages }, (_, i) => i + 1).map(page => (
              <button
                key={page}
                onClick={() => fetchProducts(page)}
                className={page === pagination.current_page ? 'active' : ''}
              >
                {page}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default ProductList;
```

### Vue.js Integration

```vue
<template>
  <div class="product-list">
    <div class="controls">
      <select v-model="sortBy" @change="fetchProducts" class="sort-select">
        <option v-for="option in sortOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>
    </div>

    <div v-if="loading" class="loading">Loading...</div>
    
    <div v-else>
      <div class="products-grid">
        <div v-for="product in products" :key="product.id" class="product-card">
          <h3>{{ product.name }}</h3>
          <p>${{ product.price }}</p>
          <p>Category: {{ product.category.name }}</p>
          <p>Brand: {{ product.brand.name }}</p>
        </div>
      </div>

      <div class="pagination">
        <button 
          v-for="page in totalPages" 
          :key="page"
          @click="fetchProducts(page)"
          :class="{ active: page === currentPage }"
        >
          {{ page }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'ProductList',
  data() {
    return {
      products: [],
      loading: false,
      sortBy: 'name:asc',
      currentPage: 1,
      totalPages: 1,
      sortOptions: [
        { value: 'name:asc', label: 'Name A-Z' },
        { value: 'name:desc', label: 'Name Z-A' },
        { value: 'price:asc', label: 'Price Low-High' },
        { value: 'price:desc', label: 'Price High-Low' },
        { value: 'category__name:asc', label: 'Category A-Z' },
        { value: 'c_popularity:desc', label: 'Most Popular' },
        { value: 'c_rating:desc', label: 'Best Rated' }
      ]
    };
  },
  mounted() {
    this.fetchProducts();
  },
  methods: {
    async fetchProducts(page = 1) {
      this.loading = true;
      try {
        const response = await axios.get('/api/v1/products', {
          params: {
            sort: this.sortBy,
            page: page,
            per_page: 12
          }
        });
        
        this.products = response.data.products;
        this.currentPage = response.data.pagination.current_page;
        this.totalPages = response.data.pagination.total_pages;
      } catch (error) {
        console.error('Error fetching products:', error);
        if (error.response?.status === 400) {
          this.sortBy = 'name:asc';
          this.$nextTick(() => this.fetchProducts());
        }
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

### URL State Management

```javascript
// utils/urlStateManager.js
class URLStateManager {
  constructor() {
    this.params = new URLSearchParams(window.location.search);
  }

  getSort() {
    return this.params.get('sort') || 'name:asc';
  }

  setSort(sortBy) {
    this.params.set('sort', sortBy);
    this.updateURL();
  }

  getPage() {
    return parseInt(this.params.get('page')) || 1;
  }

  setPage(page) {
    this.params.set('page', page.toString());
    this.updateURL();
  }

  getFilters() {
    return {
      category: this.params.get('category'),
      brand: this.params.get('brand'),
      search: this.params.get('search')
    };
  }

  setFilter(key, value) {
    if (value) {
      this.params.set(key, value);
    } else {
      this.params.delete(key);
    }
    this.updateURL();
  }

  updateURL() {
    const newURL = `${window.location.pathname}?${this.params.toString()}`;
    window.history.replaceState({}, '', newURL);
  }

  buildAPIParams() {
    const params = {};
    for (const [key, value] of this.params.entries()) {
      params[key] = value;
    }
    return params;
  }
}

export default URLStateManager;
```

## Testing Your Integration

### Model Testing

```ruby
# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "sorting functionality" do
    # Use shared examples for basic functionality
    it_behaves_like "sortable by columns", {
      allowed_columns: [:name, :price, :created_at, :category__name, :brand__name],
      disallowed_column: :internal_notes,
      associated_column: {
        name: :category__name,
        expected_sql: "categories.name"
      }
    }

    # Test custom scopes
    describe "custom scope sorting" do
      let!(:popular_product) { create(:product, view_count: 100) }
      let!(:unpopular_product) { create(:product, view_count: 10) }

      before do
        create_list(:order_item, 5, product: popular_product)
        create_list(:order_item, 1, product: unpopular_product)
      end

      it "sorts by popularity score correctly" do
        result = Product.sorted_by_columns("c_popularity:desc")
        expect(result.first).to eq(popular_product)
        expect(result.last).to eq(unpopular_product)
      end
    end
  end
end
```

### Controller Testing

```ruby
# spec/controllers/products_controller_spec.rb
require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  describe "GET #index" do
    let!(:product_a) { create(:product, name: "Apple") }
    let!(:product_b) { create(:product, name: "Banana") }

    it "sorts products correctly" do
      get :index, params: { sort: "name:desc" }
      
      expect(assigns(:products).to_a).to eq([product_b, product_a])
    end

    it "handles invalid sort parameters gracefully" do
      expect { get :index, params: { sort: "invalid_column:asc" } }
        .not_to raise_error
    end
  end
end
```

## Best Practices Summary

1. **Use descriptive custom scope names** that match the `c_` naming convention
2. **Include all necessary associations** in your `includes()` calls for performance
3. **Handle both development and production environments** appropriately
4. **Provide fallback sorting** when sort parameters are invalid
5. **Use the shared examples** provided by the gem for consistent testing
6. **Consider pagination** when implementing sorting in views
7. **Test both happy path and error scenarios** in your integration tests
8. **Use URL state management** in frontend applications for better UX
9. **Provide clear sorting options** in your UI/API documentation
10. **Monitor performance** of custom scopes, especially those with complex joins

This comprehensive set of examples should give you a solid foundation for integrating Saltbox::SortByColumns into your Rails applications across various use cases and architectural patterns. 
