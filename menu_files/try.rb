module Try
    def try data, keys
        return data if data.nil? ## if res_string is == nil stop and return nil as a result
        value = data[keys.shift] ##we dont want to shift by deleting first element, do we?
        unless keys.empty?
            try(value, keys)
        else
            value
        end
    end
end
