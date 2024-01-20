# frozen_string_literal: true

require 'spec_helper'

class Bear < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  schema do
    integer :id
    string :name
  end
end

RSpec.describe Hawk, '#save' do
  let(:bear_attributes) do
    {
      id: 1, name: 'Paddington'
    }
  end

  it 'triggers an HTTP request' do
    stub_request(:PUT, 'https://example.org/bears')
      .with(body: { 'name' => 'Paddington' },
            headers: {
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus'
            })
      .to_return(status: 200, body: bear_attributes.to_json, headers: {})
    paddington = Bear.new.tap { |b| b.name = 'Paddington' }
    expect { paddington.save }.not_to raise_error
  end
end
