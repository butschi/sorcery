module Sorcery
  module Controller
    module Submodules
      module External
        module Providers
          # This module adds support for OAuth with dropbox.com.
          # When included in the 'config.providers' option, it adds a new option, 'config.dropbox'.
          # Via this new option you can configure Dropbox specific settings like your app's key and secret.
          #
          #   config.dropbox.key = <key>
          #   config.dropbox.secret = <secret>
          #   ...
          #
          module Dropbox
            def self.included(base)
              base.module_eval do
                class << self
                  attr_reader :dropbox
                  # def dropbox(&blk) # allows block syntax.
                  #   yield @dropbox
                  # end                           

                  def merge_dropbox_defaults!
                    @defaults.merge!(:@dropbox => DropboxClient)
                  end
                end
                merge_dropbox_defaults!
                update!
              end
            end
            
            module DropboxClient
              class << self
                attr_accessor :key,
                              :secret,
                              :callback_url,
                              :site,
                              :user_info_path,
                              :user_info_mapping
                attr_reader   :access_token

                include Protocols::Oauth1
				
				        # Override included get_consumer method to provide authorize_path
				        def get_consumer
                  ::OAuth::Consumer.new(@key, @secret,
                                        :site => @site,
                                        :request_token_path =>  "/1/oauth/request_token",
                                        :authorize_path     =>  "#{@site_auth}/1/oauth/authorize",
                                        :access_token_path  =>  "/1/oauth/access_token")
                end
                
                def init
                  @site           = "https://api.dropbox.com"
                  @site_auth      = "https://www.dropbox.com"
                  @user_info_path = "/1/account/info"
                  @user_info_mapping = {}
                end
                
                def get_user_hash
                  user_hash = {}
                  response = @access_token.get(@user_info_path)
                  user_hash[:user_info] = JSON.parse(response.body)
                  user_hash[:uid] = user_hash[:user_info]['uid'].to_s
                  user_hash
                end
                
                def has_callback?
                  true
                end
                
                # calculates and returns the url to which the user should be redirected,
                # to get authenticated at the external provider's site.
                def login_url(params,session)
                  req_token = self.get_request_token
                  session[:request_token]         = req_token.oauth_token
                  session[:request_token_secret]  = req_token.oauth_token_secret
                  self.authorize_url({:request_token => req_token.oauth_token, :request_token_secret => req_token.oauth_token_secret})
                end
                
                # tries to login the user from access token
                def process_callback(params,session)
                  args = {}
                  args.merge!({:oauth_verifier => params[:oauth_verifier], :request_token => session[:request_token], :request_token_secret => session[:request_token_secret]})
                  args.merge!({:code => params[:code]}) if params[:code]
                  @access_token = self.get_access_token(args)
                end

              end  
              init
            end
          end
        end
      end
    end
  end
end
