function result = demoFun(fun, list)
    for i= 1:length(list)
        result(i) = fun(list(i))
    end
end