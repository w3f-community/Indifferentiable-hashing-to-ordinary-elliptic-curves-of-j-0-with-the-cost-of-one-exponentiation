# Dmitrii Koshelev (the author of the code) was supported by Web3 Foundation (W3F).
# Throughout the code the notation is consistent with author's article 
# [1] "Indifferentiable hashing to ordinary elliptic Fq-curves of j = 0 with the cost of one exponentiation in Fq", 
# Designs, Codes and Cryptography, 90:3 (2022), 801-812.

import hashlib
import random
import string

NUMBER_TEST_HASHES = 100
##########################################################################################################################

# generates a random string, computes its hash and makes sure that the resulting point resides on the given curve.
# 
def hash_random_point_to_curve(ec_with_0_j_inv):
        symbols = string.ascii_letters + string.digits
        length = random.randint(0,50)
        s = ''.join( random.choices(symbols, k=length) )
        X,Y,Z = H(s)
        assert(ec_with_0_j_inv(X,Y,Z)) #make sure the resulting point resides on the curve
        print( f"\nH({s}): S^* → E   =   ({X} : {Y} : {Z})   =   {ec_with_0_j_inv(X,Y,Z)}\n" )


#given a constant b and finite field Fq it compute hashes of several random string into E(Fq): y^2= x^3+b make sure the results residing on the curve
def test_several_hashes(Fq, b, number_of_attemps):
        Eb = EllipticCurve(Fq, [0,b])
        print(f"testing hashing to {Eb}")
        for i in range(0,number_of_attemps):
                hash_random_point_to_curve(Eb)


# We will deal with an ordinary elliptic curve Eb: y^2 = x^3 + b (of j-invariant 0) over a finite field Fq.
# Suppose that the order q = 1 (mod 3), but q != 1 (mod 27). Besides, b is assumed to be a quadratic residue in Fq.
# Consider some pairing-friendly curves popular at the moment:

# Parameters for BLS12-377 curve (from https://eips.ethereum.org/EIPS/eip-2539):
u = 9586122913090633729
l = u^4 - u^2 + 1
q = ((u - 1)^2 * l) // 3 + u	# q mod 9 = 7
b = 1  
X0 = 0x8848defe740a67c8fc6225bf87ff5485951e2caa9d41bb188282c8bd37cb5cd5481512ffcd394eeab9b16eb21be9ef
Y0 = 0x1914a69c5102eff1f674f5d30afeec4bd7fb348ca3e52d96d182ad44fb82305c2fe3d3634a9591afd82de55559c8ea6
Z0 = 1
print(u)
test_several_hashes(Fq,b,NUMBER_TEST_HASHES)

# Parameters for BLS12-381 curve (from https://hackmd.io/@benjaminion/bls12-381):
u = -0xd201000000010000
l = u^4 - u^2 + 1
q = ((u - 1)^2 * l) // 3 + u	# q mod 27 = 10
b = 4
X0 = 4
Y0 = 0xa989badd40d6212b33cffc3f3763e9bc760f988c9926b26da9dd85e928483446346b8ed00e1de5d5ea93e354abe706c
Z0 = 1
print(u)
test_several_hashes(Fq,b,NUMBER_TEST_HASHES)

# Parameters for BLS12-383 curve (from https://gitlab.inria.fr/tnfs-alpha/alpha/-/blob/master/sage/tnfs/param/testvector_sparseseed.py): 
u = 2^64 + 2^51 + 2^24 + 2^12 + 2^9
l = u^4 - u^2 + 1
q = ((u - 1)^2 * l) // 3 + u	# q mod 27 = 19
b = 4
X0 = 0
Y0 = 1
Z0 = 0
print(u)
test_several_hashes(Fq,b,NUMBER_TEST_HASHES)

# Parameters for a sextic Fq-twist of BN-224 curve (from https://www.iso.org/obp/ui/#iso:std:iso-iec:15946:-5:ed-3:v1:en):
q = 0xfffffffffff107288ec29e602c4520db42180823bb907d1287127833		# q mod 9 = 4
b = 1
X0 = 0
Y0 = 1
Z0 = 0
test_several_hashes(Fq,b,NUMBER_TEST_HASHES)

# This twist is meaningless for cryptography. It is included as a testing example to cover the remaining case q mod 9 = 4.
# I did not find BLS12 curves for which the given case occurs. At the same time, BN curves (unlike their twists) are of prime order, 
# hence for them the new hash function is never relevant.

   
##########################################################################################################################


# Precomputations and checking conditions
assert( log(q,2).n() <= 383 )		# This bound is used below for indifferentiability of the hash function eta(s)
assert( q.is_prime_power() ) 
r = q % 27
assert(r != 1)
assert(r % 3 == 1)
Fq = GF(q)

w = Fq(1).nth_root(3)
assert(w != 1)   # w is a primitive 3rd root of unity
w2 = w^2
b = Fq(b)
assert( b.is_square() )
sb = b.nth_root(2)   
X0 = Fq(X0); Y0 = Fq(Y0); Z0 = Fq(Z0)
assert(Y0^2*Z0 == X0^3 + b*Z0^3)

if r % 9 == 1:
	m = (q - r) // 27
	z = w.nth_root(3)   # z (i.e., zeta from [1, Section 3]) is a primitive 9th root of unity
	z2 = z^2
	c = z	
else:
	r = r % 9
	m = (q - r) // 9
	c = w
# In both cases, c is a cubic non-residue in Fq


##########################################################################################################################

  
# Finding a cubic root of u/v in Fq (if any) with the cost of one exponentiation in Fq (in particular, without inverting v)
def crtRatio(u,v):
	assert(v != 0)
	if r == 4:
		u2 = u^2
		u3 = u*u2
		u4 = u2^2
		u8 = u4^2
		return u3*(u8*v)^m
	elif r == 7:
		v2 = v^2 
		v4 = v2^2 
		v5 = v*v4
		v8 = v4^2
		return u*v5*(u*v8)^m
	elif r == 10:
		u2 = u^2
		v2 = v^2
		v4 = v2^2
		v8 = v4^2
		v9 = v*v8
		v16 = v8^2
		v25 = v9*v16
		return u*v8*(u2*v25)^m
	else:	 # r == 19
		v2 = v^2
		v4 = v2^2
		v8 = v4^2
		v16 = v8^2
		v17 = v*v16
		v25 = v8*v17
		v26 = v*v25
		return u*v17*(u*v26)^m
	# The conditions depend only on the public value r, hence this function works in constant time despite the presence of elif
	

##########################################################################################################################


# In [1, Section 2] we deal with a Calabi-Yau threefold defined as 
# the quotient T := Eb x Eb' x Eb'' / [w] x [w] x [w],
# where Eb', Eb'' are the cubic twists of Eb
# and [w](x, y) -> (wx, y) is an automorphism of order 3 on Eb, Eb', and Eb''. 

# Auxiliary map h': T(Fq) -> Eb(Fq):
def hPrime(num0,num1,num2,den, t1,t2):
	v = den^2
	u = num0^2 - b*v
	th = crtRatio(u,v)   # theta from [1, Section 3]
	v = th^3*v
	L = [t1, w*t1, w2*t1]
	L.sort()
	n = L.index(t1)
	
	if r % 9 == 1:
		u3 = u^3
		v3 = v^3
		if v3 == u3:
			X = w^n*th
			if v == u:
				Y = 1; Z = 1
			if v == w*u:
				Y = z; Z = z
			if v == w2*u:
				Y = z2; Z = z2
			Y = Y*num0
		if v3 == w*u3:
			X = th*t1
			zu = z*u
			if v == zu:
				Y = 1; Z = 1
			if v == w*zu:
				Y = z; Z = z
			if v == w2*zu:
				Y = z2; Z = z2
			Y = Y*num1	
		if v3 == w2*u3:
			X = th*t2
			z2u = z2*u
			if v == z2u:
				Y = 1; Z = 1
			if v == w*z2u:
				Y = z; Z = z
			if v == w2*z2u:
				Y = z2; Z = z2
			Y = Y*num2
		# elif is not used to respect constant-time execution in future low-level implementations
		Z = Z*den
	else:				
		if v == u:
			X = w^n*th
			Y = num0 
		if v == w*u:
			X = th*t1 
			Y = num1
		if v == w2*u:
			X = th*t2
			Y = num2 
		Z = den
		
	X = X*den
	return X,Y,Z
	
	
#################################################################################################
	

# [1, Lemma 1] states that T is given in the affine space A^5(y0,y1,y2,t1,t2) by the two equations       
# y1^2 - b = c*(y0^2 - b)*t1^3, 
# y2^2 - b = c^2*(y0^2 - b)*t2^3,
# where tj := xj/x0.
# The threefold T can be regarded as an elliptic curve in A^3(y0,y1,y2) over the function field F := Fq(s1,s2),
# where sj := tj^3. 
# By virtue of [1, Theorem 2] the non-torsion part of the Mordell-Weil group T(F) is generated by phi from [1, Theorem 1].

# Rational map phi: (Fq)^2 -> T(Fq):
def phi(t1,t2):
	s1 = t1^3
	s2 = t2^3
	s1s1 = s1^2
	s2s2 = s2^2
	s1s2 = s1*s2
	
	c2 = c^2
	c3 = c*c2
	c4 = c2^2
	a20 = c2*s1s1
	a11 = 2*c3*s1s2
	a10 = 2*c*s1
	a02 = c4*s2s2
	a01 = 2*c2*s2
	
	num0 = sb*(a20 - a11 + a10 + a02 + a01 - 3)
	num1 = sb*(-3*a20 + a11 + a10 + a02 - a01 + 1)
	num2 = sb*(a20 + a11 - a10 - 3*a02 + a01 + 1)
	den = a20 - a11 - a10 + a02 - a01 + 1	
	
	"""
	y0 = num0/den
	y1 = num1/den
	y2 = num2/den
	g0 = y0^2 - b
	g1 = y1^2 - b
	g2 = y2^2 - b
	assert(g1 == c*g0*s1)
	assert(g2 == c2*g0*s2)
	"""
	
	return num0,num1,num2,den


###########################################################################


# Map h: (Fq)^2 -> Eb(Fq)
def h(t1,t2):
	num0,num1,num2,den = phi(t1,t2)
	X,Y,Z = hPrime(num0,num1,num2,den, t1,t2)
	if t1*t2 == 0:
		X = X0; Y = Y0; Z = Z0   
	# Without loss of the admissibility property, h can return any other Fq-point on Eb in the case t1*t2 == 0 (see [1, Section 4])
	if den == 0:
		X = 0; Y = 1; Z = 0
	return X,Y,Z 
	
	
###########################################################################	


# Indifferentiable hash function eta: {0,1}* -> (Fq)^2
def eta(s):
	s = s.encode("utf-8")
	s0 = s + b'0'
	s1 = s + b'1'
	
	# 512 >= log(q,2) + 128 + 1 or, equivalently, log(q,2) <= 383. 
	# Therefore, sha512 provides at least the 128-bit security level in according to Lemma 14 of the article
	# Brier E., et al.: Efficient indifferentiable hashing into ordinary elliptic curves. 
	# In: Rabin T. (ed) Advances in Cryptology - CRYPTO 2010, LNCS, 6223, pp. 237-254. Springer, Berlin (2010).
	# If the bound on log(q,2) is not fulfilled, instead of sha512, it is necessary to take a hash function 
	# whose output length is appropriately greater than 512.
	
	hash0 = hashlib.sha512(s0).hexdigest()
	hash0 = int(hash0, base=16)
	hash1 = hashlib.sha512(s1).hexdigest()
	hash1 = int(hash1, base=16)
	return Fq(hash0), Fq(hash1)
		
		
##########################################################################################################################		
	
	
# Resulting hash function H: {0,1}* -> Eb(Fq)
def H(s):
	t1,t2 = eta(s)
	return h(t1,t2) 


##########################################################################################################################




