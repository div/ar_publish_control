require File.dirname(__FILE__) + '/spec_helper.rb'

describe Comment do
  before(:each) do
    Post.destroy_all
    @published_post = Post.create do |p|
      p.title         = 'some post'
      p.publish_at    = 1.day.ago
      p.unpublish_at  = 2.days.from_now
    end
    
    @unpublished_post = Post.create do |p|
      p.title         = 'some other post'
      p.publish_at    = 1.day.from_now
      p.unpublish_at  = 2.days.from_now
    end
    
    @published_comment_in_published_post = @published_post.comments.create do |c|
      c.body         = 'some comment'
      c.publish_at    = 2.day.ago
      c.unpublish_at  = 2.days.from_now
    end
    
    @published_comment_in_unpublished_post = @unpublished_post.comments.create do |c|
      c.body         = 'some other comment'
      c.publish_at    = 1.day.ago
      c.unpublish_at  = 2.days.from_now
    end
    
    @unpublished_comment_in_published_post = @published_post.comments.create do |c|
      c.body         = 'some other comment 2'
      c.publish_at    = 1.day.from_now
      c.unpublish_at  = 2.days.from_now
    end
    
    @unupublished_comment_in_unpublished_post = @unpublished_post.comments.create do |c|
      c.body         = 'some other comment 3'
      c.publish_at    = 1.day.from_now
      c.unpublish_at  = 2.days.from_now
    end
    
  end
  
  it "should find published comment at class level" do
    Comment.published.size.should == 2
  end
  
  it "should find published comments in collection" do
    @published_post.comments.published.size.should == 1
  end
  
  it "should find published comments in a collection with conditions" do
    @published_post.published_comments.size.should == 1
  end
  
  it "should work with named scope at class level" do
    Comment.published.size.should == 2
  end
  
  it "should work with named scope at collection level" do
    @published_post.comments.published.size.should == 1
  end
  
  it "should find unpublished with named scope" do
    Comment.unpublished.size.should == 2
    @published_post.comments.unpublished.size.should == 1
  end
  
  it "should chain correctly with other scopes" do
    Comment.published.desc.should == [@published_comment_in_unpublished_post,@published_comment_in_published_post]
  end
  
  it "should chain correctly with other scopes on collections" do
    @unpublished_comment_in_published_post.publish_at = @published_comment_in_published_post.publish_at + 1.hour
    @unpublished_comment_in_published_post.save
    @published_post.comments.reload
    @published_post.comments.published.desc.should == [@unpublished_comment_in_published_post,@published_comment_in_published_post]
  end
  
  it "should find all with conditional flag" do
    Comment.published_only.size.should == 2
    Comment.published_only(true).size.should == 2
    @published_post.comments.published_only(true).first.should == @published_comment_in_published_post
    @published_post.comments.published_only(false).first.should == @unpublished_comment_in_published_post
  end
  
  it "should validate that unpublish_at is greater than publish_at" do
    @published_comment_in_published_post.unpublish_at = @published_comment_in_published_post.publish_at - 1.minute
    @published_comment_in_published_post.save
    @published_comment_in_published_post.should_not be_valid
    @published_comment_in_published_post.errors.on(:unpublish_at).should == "should be greater than publication date or empty"
  end
end

# describe Post, 'with no dates' do
#   it "should be published" do
#     puts "DESTROYING #{Post.count}============="
#     Post.destroy_all
#     puts "====================================="
#     post = Post.create(:title => 'some post aaaaaaaaaaaaaaaaaaaaaaaaaaaa')
#     post.published?.should be_true
#     Post.published.include?(post).should be_true
#   end
# end

describe Post, "unpublished by default" do
  before(:each) do
    Article.destroy_all
    @a1 = Article.create(:title=>'a1')
  end
  
  it "should be valid" do
    @a1.should be_valid
  end
  
  it "should be unpublished by default" do
    @a1.published?.should_not be_true
  end
end