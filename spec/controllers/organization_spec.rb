require_relative '../spec_helper'

describe ".Organization" do
    fixtures :teams
    before(:each) do
        @team = Organization.new
    end

    context "#add_owner" do
        fixtures :users, :teams

        # covered by POST /teams
    end
end
