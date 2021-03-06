class User < ApplicationRecord
    attr_accessor :remember_token, :activation_token, :reset_token
    has_many :microposts, dependent: :destroy
    has_many :active_relationships, class_name:  "Relationship",
                                    foreign_key: "follower_id",
                                    dependent:   :destroy
    has_many :passive_relationships, class_name:  "Relationship",
                                    foreign_key: "followed_id",
                                    dependent:   :destroy
    has_many :following, through: :active_relationships,  source: :followed
    has_many :followers, through: :passive_relationships, source: :follower
    
    before_save :downcase_email
    before_create :create_activation_digest
    validates :name, presence: true, length: {maximum: 50}

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true,
                      length: {maximum: 255},
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    # Returns the hash digest of the given string.
    def User.digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # Returns a randome token
    def User.new_token
        SecureRandom.urlsafe_base64
    end

    # Remembers a user in the database for use in persistent sessions.
    def remember
        self.remember_token = User.new_token # generate token and restore
        update_attribute(:remember_digest, User.digest(remember_token)) # update digest in database
    end

    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil? # this is important for multi browser logout in first and close, reopen in another
        BCrypt::Password.new(digest).is_password?(token) # confirm login token
    end

    def forget
        update_attribute(:remember_digest, nil)
    end

    # Activates an account.
    def activate
      # update_attribute(:activated, true)
      # update_attribute(:activated_at, Time.zone.now)
      update_columns(activated: true, activated_at: Time.zone.now)
    end

    # Sends activation email.
    def send_activation_email
      UserMailer.account_activation(self).deliver_now
    end

    # Sets the password reset attributes.
    def create_reset_digest
      self.reset_token = User.new_token
      # update_attribute(:reset_digest,  User.digest(reset_token))
      # update_attribute(:reset_sent_at, Time.zone.now)
      update_columns(reset_digest: User.digest(reset_token),
                     reset_sent_at: Time.zone.now
                    )
    end

    # Sends password reset email.
    def send_password_reset_email
      UserMailer.password_reset(self).deliver_now
    end

    # Returns true if a password reset has expired.
    def password_reset_expired?
      reset_sent_at < 2.hours.ago
      # Password reset sent earlier than two hours ago.
    end

    def feed
      # Micropost.where("user_id = ?", id) <- only user's micropost
      # Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id) <- dose note sclae well..
      # Micropost.where("user_id IN (:following_ids) OR user_id = :user_id",
      #          following_ids: following_ids, user_id: id)
      following_ids = "SELECT followed_id FROM relationships
                WHERE  follower_id = :user_id"
      Micropost.where("user_id IN (#{following_ids})
                OR user_id = :user_id", user_id: id)
    end

    def follow(other_user)
      following << other_user
    end

    def unfollow(other_user)
      following.delete(other_user)
    end

    def following?(other_user)
      following.include?(other_user)
    end


    private
        # Converts email to all lower-case.
        def downcase_email
          self.email.downcase!
        end

        # Creates and assigns the activation token and digest.
        def create_activation_digest
          self.activation_token  = User.new_token
          self.activation_digest = User.digest(activation_token)
        end
end
