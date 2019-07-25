using Test
using DifferentialEquations
using CSV

@testset "Test Reactors" begin
@testset "Test liquid phase reactor simulation" begin
#Constant T and V Ideal Dilute Liquid
phaseDict = readinput("../src/testing/liquid_phase.rms")
spcs = phaseDict["phase"]["Species"]; #mechanism dictionaries index:  phaseDict[phasename]["Species" or "Reactions"]
rxns = phaseDict["phase"]["Reactions"];
solv = phaseDict["Solvents"][1]
liq = IdealDiluteSolution(spcs,rxns,solv;name="phase",diffusionlimited=true) #Define the phase (how species thermodynamic and kinetic properties calculated)
initialconds = Dict(["T"=>450.0,"P"=>1e5,"V"=>1.0e-6*1e6,"octane"=>6.154e-3*1e6,"oxygen"=>4.953e-6*1e6]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantTVDomain(phase=liq,initialconds=initialconds,constantspecies=["oxygen"]) #Define the domain (encodes how system thermodynamic properties calculated)
react = Reactor(domain,y0,(0.0,140000.01)) #Create the reactor object

sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-8); #solve the ode associated with the reactor

spcnames = getfield.(liq.species,:name)
octaneind = findfirst(isequal("octane"),spcnames)
y = sol(32977.61568)
@test y[octaneind]/sum(y) ≈ 0.461599061 rtol=3e-2 #from RMG simulator I believe the slight difference is due to better calculation of diffusion limits in RMS
end;

#Use superminimal example to test
phaseDict = readinput("../src/testing/superminimal.rms") #load mechanism dictionary
spcs = phaseDict["phase"]["Species"]; #mechanism dictionaries index:  phaseDict[phasename]["Species" or "Reactions"]
rxns = phaseDict["phase"]["Reactions"];
ig = IdealGas(spcs,rxns,name="phase")

#Constant T and P Ideal Gas
@testset "Test constant T and P reactor simulation" begin
 #Define the phase (how species thermodynamic and kinetic properties calculated)
initialconds = Dict(["T"=>1000.0,"P"=>1e5,"H2"=>0.67,"O2"=>0.33]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantTPDomain(phase=ig,initialconds=initialconds) #Define the domain (encodes how system thermodynamic properties calculated)

react = Reactor(domain,y0,(0.0,150.11094)) #Create the reactor object
sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-12); #solve the ode associated with the reactor

spcnames = getfield.(ig.species,:name)
h2ind = findfirst(isequal("H2"),spcnames)
o2ind = findfirst(isequal("O2"),spcnames)
h2oind = findfirst(isequal("H2O"),spcnames)
y = sol(20.44002454)
N = sum(y)
@test y[h2ind]/N ≈ 0.412883111 rtol=1e-4 #from RMG simulator
@test y[o2ind]/N ≈ 0.200419093 rtol=1e-4
@test y[h2oind]/N ≈ 0.386618602 rtol=1e-4
end;

#Constant V adiabatic Ideal Gas
#uses superminimal.yml mechanism
@testset "Constant volumne adiabatic reactor simulation" begin
initialconds = Dict(["T"=>1000.0,"P"=>10.0e5,"H2"=>0.67,"O2"=>0.33]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantVDomain(phase=ig,initialconds=initialconds) #Define the domain (encodes how system thermodynamic properties calculated)

react = Reactor(domain,y0,(0.0,0.101)) #Create the reactor object
sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-12); #solve the ode associated with the reactor

ts = exp.(range(log(1e-15),length=10000,stop=log(0.1)))
IDT = ts[argmax(diff([sol(t)[end] for t in ts]))] #Ignition Delay Time based on argmax(dTdt(t))

@test IDT ≈ 0.038384723436228063 rtol=1e-5 #from Cantera simulation

#test sensitivity analysis
initialconds = Dict(["T"=>1000.0,"P"=>1e5,"H2"=>0.67,"O2"=>0.33]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantTPDomain(phase=ig,initialconds=initialconds,sensitivity=true) #Define the domain (encodes how system thermodynamic properties calculated)

rmgdgdk = [[  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,  0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [ -4.17206256e-17,  -2.65921877e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,  -1.28556728e-16,  0.00000000e+00,   2.57113455e-16,
    0.00000000e+00,   0.00000000e+00,  0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [  0.00000000e+00,  -2.65921877e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00],
 [  8.34412512e-17,   2.65921877e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   2.57113455e-16,   0.00000000e+00,  -5.14226910e-16,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,],
 [  0.00000000e+00,   2.65921877e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,],
 [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   0.00000000e+00,
    0.00000000e+00,]] #from RMG

rmgdgdk = hcat(rmgdgdk...)'
N = sum(y0)
V= R*N*domain.T/domain.P
@views Gs = calcenthalpyinternalgibbs(domain.phase,domain.T,domain.P,V)[3]
cs = y0[1:length(domain.phase.species)]/V
C = sum(cs)
kfs,krevs = getkfkrevs(phase=domain.phase,T=domain.T,P=domain.P,V=V,C=C,N=N,ns=y0[1:length(domain.phase.species)],Gs=Gs,diffs=[])

dgdk = ratederivative(domain;cs=cs,V=V,T=domain.T,kfs=kfs,krevs=krevs,Us=Array{Float64,1}(),N=1.0,wV=Array{Float64,1}(),Cvave=0.0,sparse=false)

dgdkdif = (dgdk-rmgdgdk)./rmgdgdk
@test all((dgdkdif .< 1e-4) .| isnan.(dgdkdif))

#Test constantV reactor also with minimal.inp mechanism
phaseDict = readinput("../src/testing/minimal.inp") #load mechanism dictionary
spcs = phaseDict["phase"]["Species"]; #mechanism dictionaries index:  phaseDict[phasename]["Species" or "Reactions"]
rxns = phaseDict["phase"]["Reactions"];
ig = IdealGas(spcs,rxns,name="phase")

initialconds = Dict(["T"=>1000.0,"P"=>1.0e5,"Ar"=>0.9,"ethane"=>0.1]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantVDomain(phase=ig,initialconds=initialconds) #Define the domain (encodes how system thermodynamic properties calculated)
react = Reactor(domain,y0,(0.0,10.0)) #Create the reactor object
sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-12); #solve the ode associated with the reactor
y = sol(2.00000000)
N = sum(y[1:end-1]) #exclude T

spcnames = getfield.(ig.species,:name);
ethaneind = findfirst(isequal("ethane"),spcnames);
h2ind = findfirst(isequal("H2"),spcnames);
c2h4ind = findfirst(isequal("C=C"),spcnames);

@test y[ethaneind]/N ≈ 0.08554144 rtol=5e-3 #from RMG simulator
@test y[h2ind]/N ≈ 0.01313078 rtol=5e-3
@test y[c2h4ind]/N ≈ 0.01307791 rtol=5e-3
end;

# Use minimal example to test
phaseDict = readinput("../src/testing/minimal.inp") #load mechanism dictionary
spcs = phaseDict["phase"]["Species"]; #mechanism dictionaries index:  phaseDict[phasename]["Species" or "Reactions"]
rxns = phaseDict["phase"]["Reactions"];
ig = IdealGas(spcs,rxns,name="phase")

spcnames = getfield.(ig.species,:name);
ethaneind = findfirst(isequal("ethane"),spcnames);
h2ind = findfirst(isequal("H2"),spcnames);
c2h4ind = findfirst(isequal("C=C"),spcnames);

#Constant P adiabatic Ideal Gas
@testset "Test constant Pressure adiabatic reactor simulation" begin
#uses minimal.yml mechanism
initialconds = Dict(["T"=>1000.0,"P"=>1.0e5,"Ar"=>0.9,"ethane"=>0.1]) #Set simulation Initial Temp and Pressure
domain,y0 = ConstantPDomain(phase=ig,initialconds=initialconds) #Define the domain (encodes how system thermodynamic properties calculated)
react = Reactor(domain,y0,(0.0,10.0)) #Create the reactor object
sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-12); #solve the ode associated with the reactor
y = sol(2.00000000)
N = sum(y[1:end-1]) #exclude T

@test y[ethaneind]/N ≈ 0.083118 rtol=4e-3 #from RMG simulator
@test y[h2ind]/N ≈ 0.015334 rtol=4e-3
@test y[c2h4ind]/N ≈ 0.015254 rtol=4e-3
end;

#Parametrized P adiabatic Ideal Gas
@testset "Test parameterized pressure adiabatic reactor simulation" begin
#uses minima.yml mechanism
#Read the pressure profile from file
presprof = CSV.read("../src/testing/pressure_profile.csv";skipto=2,header=["Time","Pressure"])
P0 = Array(presprof.Pressure)
ts = Array(presprof.Time)
initialconds = Dict(["T"=>1000.0,"P"=>P0, "ts"=>ts, "V"=>1e-6,"Ar"=>0.9,"ethane"=>0.1])
domain,y0 = ParametrizedPDomain(phase=ig,initialconds=initialconds) #Define the domain (encodes how system thermodynamic properties calculated)
react = Reactor(domain,y0,(0.0,0.01)) #Create the reactor object
sol = solve(react.ode,DifferentialEquations.CVODE_BDF(),abstol=1e-20,reltol=1e-12); #solve the ode associated with the reactor
y = sol(0.005)
N = sum(y[1:end-1]) #exclude T

@test y[ethaneind]/N ≈ 0.09948671 rtol=4e-3 #from RMG simulator
@test y[h2ind]/N ≈ 0.0007812914 rtol=2e-2
@test y[c2h4ind]/N ≈ 0.0007827869 rtol=2e-2
end;
end;
