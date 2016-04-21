require 'spec_helper'

describe Hawk do
  it 'has a version number' do
    expect(Hawk::VERSION).not_to be nil
  end

  context 'given a class that inherits from Hawk::Model::Base' do

    class Owl < Hawk::Model::Base
      schema do
        integer :id
      end
    end

    class Pig < Hawk::Model::Base
      schema do
        integer :id
      end
    end

    it 'behaves like a Hawk model' do
      object = Owl.new
      expect(object).to be_kind_of(Hawk::Model::Base)
    end

    describe 'equality operator' do
      it 'returns true if two objects have the same id and class' do
        a = Owl.new; a.id = 123
        b = Owl.new; b.id = 123

        expect(a == b).to be_truthy
      end

      it 'fails otherwise' do
        a = Owl.new; a.id = 123
        b = Owl.new; b.id = 124
        c = Pig.new; c.id = 123

        expect(a == b).to be_falsy
        expect(a == c).to be_falsy
      end
    end
  end

end
