#!/usr/bin/env ruby

require 'rubypress'

#Put USERNAME='foo' PASSWORD='bar' HOST='kde.org' in wordpress_access.rb
require_relative 'wordpress_access'

def publish(name, title, output, categories = [], tags = [])
    wp = Rubypress::Client.new(:host => HOST,
                           :username => USERNAME,
                           :password => PASSWORD)
    postId = wp.newPost( :blog_id => "0", # 0 unless using WP Multi-Site, then use the blog id
                            :content => {
                            :post_type    => "post",
                            :post_status  => "draft",
                            :post_date    => Time.now,
                            :post_content => output,
                            :post_title   => title,
                            :post_name    => name,
                            :post_author  => 1, # 1 if there is only the admin user, otherwise the user's id
                            :terms_names  => {
                                :category => categories,
                                :post_tag => tags
                            }
                        }
                )

    url = "https://#{HOST}/wp-admin/post.php?post=#{postId}&action=edit"
    puts "Uploaded #{postId}: #{url}"
    system('firefox', url)
end
