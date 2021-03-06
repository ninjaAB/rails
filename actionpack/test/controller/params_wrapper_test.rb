require 'abstract_unit'

module Admin; class User; end; end

class ParamsWrapperTest < ActionController::TestCase
  class UsersController < ActionController::Base
    class << self
      attr_accessor :last_parameters
    end

    def parse
      self.class.last_parameters = request.params.except(:controller, :action)
      head :ok
    end
  end

  class User; end
  class Person; end

  tests UsersController

  def teardown
    UsersController.last_parameters = nil
  end

  def test_derived_name_from_controller
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu' }
      assert_parameters({ 'username' => 'sikachu', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_specify_wrapper_name
    with_default_wrapper_options do
      UsersController.wrap_parameters :person

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu' }
      assert_parameters({ 'username' => 'sikachu', 'person' => { 'username' => 'sikachu' }})
    end
  end

  def test_specify_wrapper_model
    with_default_wrapper_options do
      UsersController.wrap_parameters Person

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu' }
      assert_parameters({ 'username' => 'sikachu', 'person' => { 'username' => 'sikachu' }})
    end
  end

  def test_specify_only_option
    with_default_wrapper_options do
      UsersController.wrap_parameters :only => :username

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_specify_except_option
    with_default_wrapper_options do
      UsersController.wrap_parameters :except => :title

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_specify_both_wrapper_name_and_only_option
    with_default_wrapper_options do
      UsersController.wrap_parameters :person, :only => :username

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'person' => { 'username' => 'sikachu' }})
    end
  end

  def test_not_enabled_format
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/xml'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer' })
    end
  end

  def test_wrap_parameters_false
    with_default_wrapper_options do
      UsersController.wrap_parameters false
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer' })
    end
  end

  def test_specify_format
    with_default_wrapper_options do
      UsersController.wrap_parameters :format => :xml

      @request.env['CONTENT_TYPE'] = 'application/xml'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'username' => 'sikachu', 'title' => 'Developer' }})
    end
  end

  def test_not_wrap_reserved_parameters
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'authenticity_token' => 'pwned', '_method' => 'put', 'utf8' => '&#9731;', 'username' => 'sikachu' }
      assert_parameters({ 'authenticity_token' => 'pwned', '_method' => 'put', 'utf8' => '&#9731;', 'username' => 'sikachu', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_no_double_wrap_if_key_exists
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'user' => { 'username' => 'sikachu' }}
      assert_parameters({ 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_nested_params
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'person' => { 'username' => 'sikachu' }}
      assert_parameters({ 'person' => { 'username' => 'sikachu' }, 'user' => {'person' => { 'username' => 'sikachu' }}})
    end
  end

  def test_derived_wrapped_keys_from_matching_model
    User.expects(:respond_to?).with(:column_names).returns(true)
    User.expects(:column_names).returns(["username"])

    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_derived_wrapped_keys_from_specified_model
    with_default_wrapper_options do
      Person.expects(:respond_to?).with(:column_names).returns(true)
      Person.expects(:column_names).returns(["username"])

      UsersController.wrap_parameters Person

      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
      assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'person' => { 'username' => 'sikachu' }})
    end
  end

  private
    def with_default_wrapper_options(&block)
      @controller.class._wrapper_options = {:format => [:json]}
      @controller.class.inherited(@controller.class)
      yield
    end

    def assert_parameters(expected)
      assert_equal expected, UsersController.last_parameters
    end
end

class NamespacedParamsWrapperTest < ActionController::TestCase
  module Admin
    module Users
      class UsersController < ActionController::Base;
        class << self
          attr_accessor :last_parameters
        end

        def parse
          self.class.last_parameters = request.params.except(:controller, :action)
          head :ok
        end
      end
    end
  end

  class SampleOne
    def self.column_names
      ["username"]
    end
  end

  class SampleTwo
    def self.column_names
      ["title"]
    end
  end

  tests Admin::Users::UsersController

  def teardown
    Admin::Users::UsersController.last_parameters = nil
  end

  def test_derived_name_from_controller
    with_default_wrapper_options do
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :parse, { 'username' => 'sikachu' }
      assert_parameters({'username' => 'sikachu', 'user' => { 'username' => 'sikachu' }})
    end
  end

  def test_namespace_lookup_from_model
    Admin.const_set(:User, Class.new(SampleOne))
    begin
      with_default_wrapper_options do
        @request.env['CONTENT_TYPE'] = 'application/json'
        post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
        assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'username' => 'sikachu' }})
      end
    ensure
      Admin.send :remove_const, :User
    end
  end

  def test_hierarchy_namespace_lookup_from_model
    Object.const_set(:User, Class.new(SampleTwo))
    begin
      with_default_wrapper_options do
        @request.env['CONTENT_TYPE'] = 'application/json'
        post :parse, { 'username' => 'sikachu', 'title' => 'Developer' }
        assert_parameters({ 'username' => 'sikachu', 'title' => 'Developer', 'user' => { 'title' => 'Developer' }})
      end
    ensure
      Object.send :remove_const, :User
    end
  end

  private
    def with_default_wrapper_options(&block)
      @controller.class._wrapper_options = {:format => [:json]}
      @controller.class.inherited(@controller.class)
      yield
    end

    def assert_parameters(expected)
      assert_equal expected, Admin::Users::UsersController.last_parameters
    end
end