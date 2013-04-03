module Split
  class Trial
    attr_accessor :experiment
    attr_accessor :goals
    attr_accessor :logged_args
    attr_accessor :uid

    def initialize(attrs = {})
      self.uid = SecureRandom.hex(5)
      self.experiment = attrs[:experiment]  if !attrs[:experiment].nil?
      self.alternative = attrs[:alternative] if !attrs[:alternative].nil?
      #self.goals = attrs[:goals] if !attrs[:goals].nil?
      self.goals = !attrs[:goals].nil? ? attrs[:goals] : [] 
      self.logged_args = attrs[:logged_args] if !attrs[:logged_args].nil? && experiment.log_observation_data
    end

    def alternative
      @alternative ||=  if experiment.winner
                          experiment.winner
                        end
    end

    def complete!
      if alternative
        log!(:completion)
        if !self.goals.nil? && self.goals.empty?
          alternative.increment_completion
        else
          self.goals.each {|g| alternative.increment_completion(g)}
        end
      end
    end

    def choose!
      choose
      record!
    end

    def record!
      log!(:participation)
      alternative.increment_participation
    end

    def log!(action)
      args = {:uid => uid, :action => action, :args =>logged_args}
      Split.redis.rpush "experiment:#{experiment.name.to_s}:log", Split::Helper.encode(args) if !logged_args.nil? && experiment.log_observation_data
    end

    def choose
      self.alternative = experiment.next_alternative
    end

    def alternative=(alternative)
      @alternative = if alternative.kind_of?(Split::Alternative)
        alternative
      else
        self.experiment.alternatives.find{|a| a.name == alternative }
      end
    end
  end
end
