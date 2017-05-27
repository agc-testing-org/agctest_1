require 'spec_helper'
require 'api_helper'

describe "/teams" do

    fixtures :users

    before(:all) do
        @CREATE_TOKENS=true
    end


    describe "POST /" do
        before(:each) do
            @name = "NEW TEAM"
        end
        context "valid fields" do
            before(:each) do
                post "/teams", { :name => @name, :owner => @user}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @mysql = @mysql_client.query("select * from teams").first
                @res = JSON.parse(last_response.body)
            end
            context "team" do
                it "should include name" do
                    expect(@mysql["name"]).to eq(@name)
                end
                it "should include owner" do
                    expect(@mysql["org"]).to eq(@org)
                end
            end
            it "should return team id" do
                expect(@res["id"]).to eq(@mysql["id"])  
            end 
        end
    end

end
