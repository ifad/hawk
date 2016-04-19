require 'spec_helper'

describe Hawk do
  it 'has a version number' do
    expect(Hawk::VERSION).not_to be nil
  end

  context 'given a class that inherits from Hawk::Model::Base' do

    class Person < Hawk::Model::Base
    end

    it 'behaves like a Hawk model' do
      object = Person.new
      expect(object).to be_kind_of(Hawk::Model::Base)
    end
  end

end
