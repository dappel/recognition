require "recognition/transaction"

module Recognition
  # Handle all Transactions and logging to Redis
  module Database
    def self.log id, amount, bucket, code = nil
      hash = Time.now.to_f.to_s
      Recognition.backend.multi do
        Recognition.backend.hincrby "recognition:user:#{ id }:counters", 'points', amount
        Recognition.backend.hincrby "recognition:user:#{ id }:counters", bucket, amount
        Recognition.backend.zadd "recognition:user:#{ id }:transactions", hash, { hash: hash, amount: amount, bucket: bucket, datetime: DateTime.now.to_s }.to_json
        Recognition.backend.zadd 'recognition:transactions', hash, { hash: hash, id: id, amount: amount, bucket: bucket, datetime: DateTime.now.to_s }.to_json
        unless code.nil?
          Recognition.backend.zadd "recognition:voucher:#{ code }:transactions", hash, { hash: hash, id: id, bucket: bucket, datetime: DateTime.now.to_s }.to_json
        end
      end
    end
    
    def self.get key
      Recognition.backend.get key
    end
    
    def self.get_user_points id
      get_user_counter id, 'points'
    end
    
    def self.get_user_counter id, counter
      counter = Recognition.backend.hget("recognition:user:#{ id }:counters", counter)
      counter.to_i
    end
    
    def self.get_user_transactions id, page = 0, per = 20
      start = page * per 
      stop = (1 + page) * per 
      keypart = "user:#{ id }"
      self.get_transactions keypart, start, stop
    end
    
    def self.get_voucher_transactions code, page = 0, per = 20
      start = page * per
      stop = (1 + page) * per 
      keypart = "voucher:#{ code }"
      self.get_transactions keypart, start, stop
    end
    
    def self.update_points object, action, condition
      if condition[:bucket].nil?
        bucket = "#{ object.class.to_s.camelize }:#{ action }"
      else
        bucket = condition[:bucket]
      end
      user = parse_user(object, condition)
      if condition[:amount].nil? && condition[:gain].nil? && condition[:loss].nil?
        false
      else
        total = parse_amount(condition[:amount], object) + parse_amount(condition[:gain], object) - parse_amount(condition[:loss], object)
        ground_total = user.recognition_counter(bucket) + total
        if condition[:maximum].nil? || ground_total <= condition[:maximum]
          Database.log(user.id, total.to_i, bucket)
        end
      end
    end
    
    def self.redeem_voucher id, code, amount
      bucket = "Voucher:redeem##{ code }"
      Database.log(id, amount.to_i, bucket, code)
    end
    
    def self.get_user_voucher id, code
      bucket = "Voucher:redeem##{ code }"
      Database.get_user_counter id, bucket
    end
    
    def self.parse_voucher_part part, object
      case part.class.to_s
      when 'String'
        value = part
      when 'Integer'
        value = part.to_s
      when 'Fixnum'
        value = part.to_s
      when 'Symbol'
        value = object.send(part).to_s
      when 'Proc'
        value = part.call(object).to_s
      when 'NilClass'
        # Do not complain about nil amounts
      else
        raise ArgumentError, "type mismatch for voucher part: expecting 'Integer', 'Fixnum', 'Symbol' or 'Proc' but got '#{ amount.class.to_s }' instead."
      end
      value || ''
    end
    
    private
    
    def self.get_transactions keypart, start, stop
      transactions = []
      range = Recognition.backend.zrange "recognition:#{ keypart }:transactions", start, stop
      range.each do |transaction|
        transactions << JSON.parse(transaction, { symbolize_names: true })
      end
      transactions
    end
    
    def self.parse_user object, condition
      if condition[:recognizable].nil?
        user = object
      else
        case condition[:recognizable].class.to_s
        when 'Symbol'
          user = object.send(condition[:recognizable])
        when 'String'
          user = object.send(condition[:recognizable].to_sym)
        when 'Proc'
          user = object.call(condition[:proc_params])
        else
          user = condition[:recognizable]
        end
      end
      user
    end
    
    def self.parse_amount amount, object
      case amount.class.to_s
      when 'Integer'
        value = amount
      when 'Fixnum'
        value = amount
      when 'Symbol'
        value = object.send(amount)
      when 'Proc'
        value = amount.call(object)
      when 'NilClass'
        # Do not complain about nil amounts
      else
        raise ArgumentError, "type mismatch for amount: expecting 'Integer', 'Fixnum', 'Symbol' or 'Proc' but got '#{ amount.class.to_s }' instead."
      end
      value || 0
    end
  end
end