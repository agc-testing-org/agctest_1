class ParamsHelper
    def drop_key params, key
        if !params[key].nil? 
            params.delete(key)
        end
        return params
    end

    def assign_param_to_model params, key, model
        if !params[key].nil? && !params[key].empty?
            params["#{model}.#{key}"] = params[key]
        end
        drop_key params, key
        return params
    end
end
