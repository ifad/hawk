require 'spec_helper'

describe 'persisting operations' do
  class Bear < Hawk::Model::Base
    url "http://zombo.com/"
    client_name "Foobar"

    schema do
      integer :id
      string :name
    end
  end

  let(:bear_attributes) {
    {
      id: 1, name: "Paddington"
    }
  }

  describe "#save" do
    it 'triggers an HTTP request' do
      stub_request(:PUT, "http://zombo.com/bears").
        with(:body => {"name"=>"Paddington"},
             :headers => {
               'Content-Type'=>'application/x-www-form-urlencoded',
               'User-Agent'=>'Typhoeus - https://github.com/typhoeus/typhoeus'
              }).
        to_return(:status => 200, :body => bear_attributes.to_json, :headers => {})
      paddington = Bear.new.tap{|b| b.name = "Paddington"}
      expect { paddington.save }.to_not raise_error
    end
  end
end
