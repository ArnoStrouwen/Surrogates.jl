using Surrogates
using Zygote


function vector_of_tuples_to_matrix(v)
    #convert training data generated by surrogate sampling into a matrix suitable for GEKPLS
    num_rows = length(v)
    num_cols = length(first(v))
    K = zeros(num_rows, num_cols)
    for row in 1:num_rows
        for col in 1:num_cols
            K[row, col]=v[row][col]
        end
    end
    return K
end

function vector_of_tuples_to_matrix2(v)
    #convert gradients into matrix form
    num_rows = length(v)
    num_cols = length(first(first(v)))
    K = zeros(num_rows, num_cols)
    for row in 1:num_rows
        for col in 1:num_cols
            K[row, col] = v[row][1][col]
        end
    end
    return K
end

# # water flow function tests
function water_flow(x)
    r_w = x[1]
    r = x[2]
    T_u = x[3]
    H_u = x[4]
    T_l = x[5]
    H_l = x[6]
    L = x[7]
    K_w = x[8]
    log_val = log(r/r_w)
    return (2*pi*T_u*(H_u - H_l))/ ( log_val*(1 + (2*L*T_u/(log_val*r_w^2*K_w)) + T_u/T_l))
end

n = 1000
d = 8
lb = [0.05,100,63070,990,63.1,700,1120,9855]
ub = [0.15,50000,115600,1110,116,820,1680,12045]
x = sample(n,lb,ub,SobolSample())
X = vector_of_tuples_to_matrix(x)
grads = vector_of_tuples_to_matrix2(gradient.(water_flow, x))
y = reshape(water_flow.(x),(size(x,1),1))
xlimits = hcat(lb, ub)
n_test = 100 
x_test = sample(n_test,lb,ub,GoldenSample()) 
X_test = vector_of_tuples_to_matrix(x_test) 
y_true = water_flow.(x_test)

@testset "Test 1: Water Flow Function Test (dimensions = 8; n_comp = 2; extra_points = 2)" begin 
    n_comp = 2
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 0.03, atol=0.02) #rmse: 0.039
end

@testset "Test 2: Water Flow Function Test (dimensions = 8; n_comp = 3; extra_points = 2)" begin 
    n_comp = 3
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) #change hard-coded 2 param to variable
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 0.02, atol=0.01) #rmse: 0.027
end

@testset "Test 3: Water Flow Function Test (dimensions = 8; n_comp = 3; extra_points = 3)" begin 
    n_comp = 3
    delta_x = 0.0001
    extra_points = 3
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 0.02, atol=0.01) #rmse: 0.027
end

## welded beam tests
function welded_beam(x)
    h = x[1]
    l = x[2]
    t = x[3]
    a = 6000/(sqrt(2)*h*l)
    b = (6000*(14+0.5*l)*sqrt(0.25*(l^2+(h+t)^2)))/(2*(0.707*h*l*(l^2/12 + 0.25*(h+t)^2)))
    return (sqrt(a^2+b^2 + l*a*b))/(sqrt(0.25*(l^2+(h+t)^2)))
end

n = 1000
d = 3
lb = [0.125,5.0,5.0]
ub = [1.,10.,10.]
x = sample(n,lb,ub,SobolSample())
X = vector_of_tuples_to_matrix(x)
grads = vector_of_tuples_to_matrix2(gradient.(welded_beam, x))
y = reshape(welded_beam.(x),(size(x,1),1))
xlimits = hcat(lb, ub)
n_test = 100 
x_test = sample(n_test,lb,ub,GoldenSample()) 
X_test = vector_of_tuples_to_matrix(x_test) 
y_true = welded_beam.(x_test)

@testset "Test 4: Welded Beam Function Test (dimensions = 3; n_comp = 3; extra_points = 2)" begin 
    n_comp = 3
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 39.0, atol=0.5) #rmse: 38.988
end

@testset "Test 5: Welded Beam Function Test (dimensions = 3; n_comp = 2; extra_points = 2)" begin 
    n_comp = 2
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 39.5, atol=0.5) #rmse: 39.481
end

## increasing extra points increases accuracy
@testset "Test 6: Welded Beam Function Test (dimensions = 3; n_comp = 2; extra_points = 4)" begin 
    n_comp = 2
    delta_x = 0.0001
    extra_points = 4
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 37.5, atol=0.5) #rmse: 37.87
end

## sphere function tests
function sphere_function(x)
    return sum(x.^2)
end

## 3D
n = 100
d = 3
lb = [-5.0, -5.0, -5.0]
ub = [5.0, 5.0 ,5.0]
x = sample(n,lb,ub,SobolSample())
X = vector_of_tuples_to_matrix(x)
grads = vector_of_tuples_to_matrix2(gradient.(sphere_function, x))
y = reshape(sphere_function.(x),(size(x,1),1))
xlimits = hcat(lb, ub)
n_test = 100 
x_test = sample(n_test,lb,ub,GoldenSample()) 
X_test = vector_of_tuples_to_matrix(x_test) 
y_true = sphere_function.(x_test)

@testset "Test 7: Sphere Function Test (dimensions = 3; n_comp = 2; extra_points = 2)" begin
    n_comp = 2
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 0.001, atol=0.05) #rmse: 0.00083
end

## 2D
n = 50 
d = 2
lb = [-10.0, -10.0]
ub = [10.0, 10.0]
x = sample(n,lb,ub,SobolSample())
X = vector_of_tuples_to_matrix(x)
grads = vector_of_tuples_to_matrix2(gradient.(sphere_function, x))
y = reshape(sphere_function.(x),(size(x,1),1))
xlimits = hcat(lb, ub)
n_test = 10 
x_test = sample(n_test,lb,ub,GoldenSample()) 
X_test = vector_of_tuples_to_matrix(x_test) 
y_true = sphere_function.(x_test)

@testset "Test 8: Sphere Function Test (dimensions = 2; n_comp = 2; extra_points = 2" begin
    n_comp = 2
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(X, y, grads, n_comp, delta_x, xlimits, extra_points, initial_theta) 
    y_pred = g(X_test)
    rmse = sqrt(sum(((y_pred - y_true).^2)/n_test))
    @test isapprox(rmse, 0.1, atol=0.5) #rmse: 0.0022
end

@testset "Test 9: Add Point Test (dimensions = 3; n_comp = 2; extra_points = 2)" begin
    #first we create a surrogate model with just 3 input points
    initial_x_vec = [(1.0, 2.0, 3.0), (4.0, 5.0, 6.0), (7.0, 8.0, 9.0)]
    initial_y = reshape(sphere_function.(initial_x_vec), (size(initial_x_vec,1),1))
    initial_X = vector_of_tuples_to_matrix(initial_x_vec)
    initial_grads = vector_of_tuples_to_matrix2(gradient.(sphere_function, initial_x_vec))
    lb = [-5.0, -5.0, -5.0]
    ub = [10.0, 10.0, 10.0]
    xlimits = hcat(lb, ub)
    n_comp = 2
    delta_x = 0.0001
    extra_points = 2
    initial_theta = 0.01
    g = GEKPLS(initial_X, initial_y, initial_grads, n_comp, delta_x, xlimits, extra_points, initial_theta)
    n_test = 100 
    x_test = sample(n_test,lb,ub,GoldenSample()) 
    X_test = vector_of_tuples_to_matrix(x_test) 
    y_true = sphere_function.(x_test) 
    y_pred1 = g(X_test)
    rmse1 = sqrt(sum(((y_pred1 - y_true).^2)/n_test)) #rmse1 = 31.91

    #then we update the model with more points to see if performance improves
    n = 100
    x = sample(n,lb,ub,SobolSample())
    X = vector_of_tuples_to_matrix(x)
    grads = vector_of_tuples_to_matrix2(gradient.(sphere_function, x))
    y = reshape(sphere_function.(x),(size(x,1),1))
    add_point!(g, X, y, grads)
    y_pred2 = g(X_test)
    rmse2 = sqrt(sum(((y_pred2 - y_true).^2)/n_test)) #rmse2 = 0.0015
    @test (rmse2 < rmse1)
end
