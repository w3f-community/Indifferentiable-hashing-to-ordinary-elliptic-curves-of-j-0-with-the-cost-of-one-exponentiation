# Indifferentiable-hashing-to-ordinary-elliptic-curves-of-j-0-with-the-cost-of-one-exponentiation
Recently, my article https://link.springer.com/article/10.1007/s10623-022-01012-8 (cf. its free eprint version https://eprint.iacr.org/2021/301) was published in the quite prestigious cryptographic journal "Designs, Codes and Cryptography". This article provides a new hash function (indifferentiable from a random oracle) to the prime subgroup G1 of many pairing-friendly elliptic curves such as BLS12-381 and BLS12-377 (Barreto-Lynn-Scott). These curves and such hash functions are actively used in blockchains, namely in the BLS (Boneh-Lynn-Shacham) aggregate signature. My hash function is much faster than previous state-of-the-art ones, including the Wahby-Boneh indirect map. For instance, BLS12-377 is defined over a highly 2-adic finite field, hence the indifferentiable Wahby-Boneh hash function requires to apply twice the slow Tonelli-Shanks algorithm for extracting two square roots in the basic field. In comparison, the new hash function extracts only one cubic root, which can be expressed via one exponentiation in the finite field. As you can see, I have already checked the correctness of my results in the computer algebra systems Magma and Sage. A rapid (although non-constant-time) implementation in Rust can be found on the webpage https://github.com/zhenfeizhang/indifferentiable-hashing.

## Tests
To run the test use.
```
$ sage Indifferentiable\ hashing\ with\ the\ cost\ of\ one\ exponentiation.sage 
```

### To translate rust test vectors to sage test vectors
save `test_vectors.rs` to `test_vector.py` remove boilerplate code.

Add definitions:

```
from sage.rings.finite_rings.finite_field_constructor import GF

Fq381= GF(4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787)
bls12_381_test_vector = [Fq381(0)]*200

Fq377 = GF(0x01ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001)
bls12_377_test_vector = [Fq377(0)]*200
```

First schroll down to BLS12-377 test vectors and run

```
(query-replace-regexp ".*a\\[\\([0-9]*\\)\\] = MontFp!(Fq377, \"\\([0-9]*\\)\");" "bls12_377_test_vector[\\1] = Fq377(\\2);")
```

and then come to the begining of the file and run.

```
(query-replace-regexp ".*a\\[\\([0-9]*\\)\\] = MontFp!(\"\\([0-9]*\\)\");" "bls12_381_test_vector[\\1] = Fq381(\\2);")
```

in emacs.

and then run the tests as explained above.
