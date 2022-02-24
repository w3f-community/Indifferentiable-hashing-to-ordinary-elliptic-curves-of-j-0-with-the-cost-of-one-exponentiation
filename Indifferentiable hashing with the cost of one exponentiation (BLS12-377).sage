# Dmitrii Koshelev (the author of the code) was supported by Web3 Foundation (W3F)
# Throughout the code the notation is consistent with author's article 
# "Indifferentiable hashing to ordinary elliptic Fq-curves of j = 0 with the cost of one exponentiation in Fq"

import hashlib
import random
import string

# parameters for the BLS12-377 curve E1
u = 9586122913090633729
r = u^4 - u^2 + 1
q = ((u - 1)^2 * r) // 3 + u
assert( ceil(log(q,2).n()) == 377 )
assert(q.is_prime())
assert(q % 9 == 7)
m = (q - 7) // 9

Fq = GF(q)
w = Fq(1).nth_root(3)
assert(w != 1)
w2 = w^2
 

##############################################################################

	
# auxiliary map from the threefold T to E1
def hPrime(num0,num1,num2,den, t1,t2):
	v = den^2
	u = num0^2 - v
	v2 = v^2 
	v4 = v2^2 
	v5 = v*v4
	v8 = v4^2
	th = u*v5*(u*v8)^m   # theta
	v = th^3*v
	L = [t1, w*t1, w2*t1]
	L.sort()
	n = L.index(t1)

	if v == u:
		X = w^n*th
		Y = num0 
	if v == w*u:
		X = th*t1 
		Y = num1
	if v == w2*u:
		X = th*t2
		Y = num2 
	# elif is not used to respect constant-time execution
		
	X = X*den
	Z = den
	return X,Y,Z
	

# rational map Fq^2 -> T(Fq)
def phi(t1,t2):
	s1 = t1^3
	s2 = t2^3
	s1s1 = s1^2
	s2s2 = s2^2
	global s1s2
	s1s2 = s1*s2
	
	a20 = w2*s1s1
	a11 = 2*s1s2
	a10 = 2*w*s1
	a02 = w*s2s2
	a01 = 2*w2*s2
	
	num0 = a20 - a11 + a10 + a02 + a01 - 3
	num1 = -3*a20 + a11 + a10 + a02 - a01 + 1
	num2 = a20 + a11 - a10 - 3*a02 + a01 + 1
	den = a20 - a11 - a10 + a02 - a01 + 1
	return num0,num1,num2,den


# map Fq^2 -> E1(Fq)
def h(t1,t2):
	num0,num1,num2,den = phi(t1,t2)
	X,Y,Z = hPrime(num0,num1,num2,den, t1,t2)
	if s1s2 == 0:
		X = 0; Y = 1; Z = 1
	if den == 0:
		X = 0; Y = 1; Z = 0
	return X,Y,Z
	

# hash function to the plane Fq^2
def eta(s):
	s = s.encode("utf-8")
	s0 = s + b'0'
	s1 = s + b'1'
	# 512 > 506 = 377 + 128 + 1, hence sha512 provides the 128-bit security level
	# (see Lemma 14 of Brier et al.'s article)
	hash0 = hashlib.sha512(s0).hexdigest()
	hash0 = int(hash0, base=16)
	hash1 = hashlib.sha512(s1).hexdigest()
	hash1 = int(hash1, base=16)
	return Fq(hash0), Fq(hash1)
		
	
# resulting hash function to E1(Fq)	
def H(s):
	t1,t2 = eta(s)
	return h(t1,t2)


##############################################################################


# main 
symbols = string.ascii_letters + string.digits
length = random.randint(0,50)
s = ''.join( random.choices(symbols, k=length) )
E1 = EllipticCurve(Fq, [0,1])
X,Y,Z = H(s)
print( f"\nH({s})   =   ({X} : {Y} : {Z})   =   {E1(X,Y,Z)}\n" )
