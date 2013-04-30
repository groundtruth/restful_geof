require "spec_helper"
require "pozi_api/routes"

module PoziAPI
  describe Routes do
    describe ".route" do

      context "given invalid request" do
        let(:request) { stub(path_info: "/some/invalid/path").as_null_object }
        it "should return 400 (Bad Request)" do
          subject.route(request).should == 400
        end
      end

      context "given valid request" do
        let(:store) { mock("Store") }

        before :each do
          Store.stub(:new).and_return(store)
        end
        
        describe "read actions" do
          
          it "should handle basic read requests, returning the result" do
            request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable")
            result = mock("result")
            Store.should_receive(:new).with("mydb", "mytable")
            store.should_receive(:find).and_return(result)
            subject.route(request).should == result
          end

          it "should handle field lookup conditions" do
            request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable/groupid/is/2/name/matches/mr%20ed/typeid/is/44/limit/1")
            store.should_receive(:find).with(hash_including(is: [{ "groupid" => "2" }, { "typeid" => "44" }]))
            subject.route(request)
          end

          it "should get full text search conditions" do
            request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/1")
            store.should_receive(:find).with(hash_including(matches: [{ "name" => "mr ed" }]))
            subject.route(request)
          end
          
          it "should get limit conditions" do
            request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/3")
            store.should_receive(:find).with(hash_including(limit: 3))
            subject.route(request)
          end

          it "should not pass limit if not given" do
            request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable/groupid/is/2/name/matches/mr%20ed")
            store.should_receive(:find).with { |conditions| conditions.keys.include?(:limit).should be_false }
            subject.route(request)
          end

        end
        
      end


    end
  end
end

