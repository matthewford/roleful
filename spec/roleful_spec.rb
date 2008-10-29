require File.dirname(__FILE__) + '/spec_helper'

describe Roleful do
  attr_reader :klass, :object
  
  before(:each) do
    @klass = Class.new do
      attr_reader :role
      
      def initialize(role=nil)
        @role = role
      end
      
      include Roleful
    end
  end
  
  it "adds ROLES to class" do
    proc {
      klass::ROLES
    }.should_not raise_error
  end
  
  it "has :null role by default" do
    klass::ROLES[:null].should_not be_nil
  end
  
  it "allows roles to be added" do
    klass.role :admin
    klass::ROLES[:admin].should_not be_nil
  end
  
  describe "role predicate helpers" do
    before(:each) do
      klass.role :admin
    end
    
    it "return true if proper role" do
      klass.new(:admin).should be_admin
    end
    
    it "returns if not proper role" do
      klass.new.should_not be_admin
    end
  end
  
  describe "delegating permissions to role" do
    before(:each) do
      klass.role(:admin) { can :view_foos }
    end
    
    it "works for declared roles" do
      object = klass.new(:admin)
      object.can_view_foos?.should be_true
    end
    
    it "works with built-in null object" do
      object = klass.new
      object.can_view_foos?.should be_false
    end
    
    describe "#can?" do
      context "as object with role" do
        it "returns true or false depending on the permission" do
          object = klass.new(:admin)
          object.can?(:view_foos).should be_true
        end
      end
      
      context "as object without role" do
        it "returns true or false depending on the permission" do
          object = klass.new
          object.can?(:view_foos).should be_false
        end
      end
    end
    
    describe ":null role" do
      it "returns false when permission exists elsewhere" do
        klass.new.can_view_foos?.should_not be
      end

      it "blows up when permission hasn't been declared" do
        proc {
          klass.new.can_eat_cheese?
        }.should raise_error(NoMethodError)
      end
    end
    
    describe ":superuser role" do
      it "is always true" do
        klass.role(:super_admin, :superuser => true)
        object = klass.new(:super_admin)
        object.can_view_foos?.should be_true
      end
    end
  end
  
  describe "with instance-specific permissions" do
    before(:each) do
      klass.role :admin do
        can(:be_self) { |that| self == that }
        can(:equal_two) { |sym| :two == sym }
      end
    end
    
    it "taking a block" do
      object = klass.new(:admin)
      object.can_equal_two?(:one).should be_false
      object.can_equal_two?(:two).should be_true
    end
    
    context "as object with role" do
      it "binding self to instance" do
        object = klass.new(:admin)
        object.can_be_self?(object).should be_true
      end
    end
    
    context "as object without role" do
      it "binding self to instance" do
        object = klass.new
        object.can_be_self?(object).should be_false
      end
    end
  end
end