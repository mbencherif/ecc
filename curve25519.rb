# Curve25519+ECDH implementation in Ruby
# Disclaimer: This code is for learning purposes ONLY. It is NOT secure.
# Tanner Prynn

require 'SecureRandom'
require 'digest'

def modexp(base, exp, mod)
    prod = 1
    base = base % mod
    until exp.zero?
      exp.odd? and prod = (prod * base) % mod
      exp >>= 1
      base = (base * base) % mod
    end
    prod
end

def egcd(a, b)
    if a == 0
        return b, 0, 1
    else
        g, y, x = egcd(b % a, a)
        return g, (x - (b / a) * y), y
    end
end

def modinv(a, m)
	if a < 0
		return modinv(a % m, m)
	end

    g, x, y = egcd(a, m)
    if g != 1
        fail 'modular inverse does not exist'
    else
        return x % m
    end
end

module Curve25519
	# Spec: http://cr.yp.to/ecdh/curve25519-20060209.pdf
	# Group Operations: https://hyperelliptic.org/EFD/g1p/auto-montgom.html

	# Curve25519 is an EC curve in Montgomery form:
	# b*y^2 = x^3 + a*x^2 + x
	P = 2**255 - 19
	A = 486662
	B = 1

	class Point
		attr_reader :x
		attr_reader :y

		def initialize(x, y)
			if !(x == 0 && y == 1)
				raise "Invalid Point" unless 
					(Curve25519::B * y**2) % Curve25519::P == 
						(x**3 + Curve25519::A * x**2 + x) % Curve25519::P
			end

			@x = x % Curve25519::P
			@y = y % Curve25519::P
		end

		def ==(o)
			return o.class == self.class && o.x == @x && o.y == @y
		end

		def infty?
			return self == Curve25519::Inf
		end

		def add(o)
			return Curve25519.add(self, o)
		end

		def double
			return Curve25519.double(self)
		end

		def mult(n)
			return Curve25519.mult(n, self)
		end
	end

	# homogenous form b*y^2*z = x^3 + a*x^2*z + x*z^2
	# z = 0 -> x^3 = 0 -> x = 0
	# => point at infinity is (0,1,0)
	Inf = Point.new(0, 1)

	# Base point specified by Bernstein
	Base = Point.new(9, 14781619447589544791020593568409986887264606134616475288964881837755586237401)

	def Curve25519.add(p1, p2)
		if p1.infty?
			return p2
		elsif p2.infty?
			return p1
		elsif p1 == p2
			return Curve25519.double(p1)
		elsif p1.x == p2.x && p1.y != p2.y
			return Curve25519::Inf
		end

		x1 = p1.x
		y1 = p1.y
		x2 = p2.x
		y2 = p2.y
		
		# x3 = b*(y2-y1)^2/(x2-x1)^2-a-x1-x2
		n = (B*modexp(y2-y1, 2, P)) % P
		d = modinv(modexp(x2-x1, 2, P), P)
		x3 = ((n * d) - A - x1 - x2) % P

		# y3 = (2*x1+x2+a)*(y2-y1)/(x2-x1)-b*(y2-y1)^3/(x2-x1)^3-y1
		t1 = (((2*x1) + x2 + A) * (y2 - y1) * modinv(x2-x1, P)) % P
		t2 = (B * modexp(y2 - y1, 3, P) * modexp(modinv(x2-x1, P), 3, P)) % P
		y3 = (t1 - t2 - y1) % P

		return Point.new(x3, y3)
	end

	def Curve25519.double(p1)
		if p1.infty?
			return Curve25519::Inf
		end

		x1 = p1.x
		y1 = p1.y

		# x3 = b*(3*x1^2+2*a*x1+1)^2/(2*b*y1)^2-a-x1-x1
		n = (B * modexp(3*modexp(x1, 2, P) + 2*A*x1 + 1, 2, P)) % P
		d = modinv(modexp(2 * B * y1, 2, P), P)
		x3 = n*d - A - x1 - x1 % P

  		# y3 = (2*x1+x1+a)*(3*x1^2+2*a*x1+1)/(2*b*y1)-b*(3*x1^2+2*a*x1+1)^3/(2*b*y1)^3-y1
  		n1 = ((2*x1 + x1 + A)*(3*modexp(x1, 2, P) + 2*A*x1 + 1)) % P
  		d1 = modinv(2*B*y1, P)
  		n2 = (B*modexp(3*modexp(x1, 2, P) + 2*A*x1 + 1, 3, P)) % P
  		d2 = modinv(modexp(2*B*y1, 3, P), P)
  		y3 = n1*d1 - n2*d2 - y1

  		return Point.new(x3, y3)
	end

	def Curve25519.mult(n, p1)
		# See http://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_multiplication
		# This multiplication is vulnerable to timing/power analysis!
		# Secure ec multiplication uses the Montgomery ladder which works in fixed-time

		p3 = Curve25519::Inf

		n.to_s(2).split("").each do |bit|
			p3 = p3.double
			if bit == "1"
				p3 = p3.add(p1)	
			end
		end

		return p3
	end

end

module ECDH
	class User
		attr_reader :name
		attr_reader :public_key

		attr_reader :keys

		def initialize(name = nil, secret = nil)
			@name = name
			@keys = Hash.new

			if secret
				@secret % Curve25519::P
			else
				secret = SecureRandom.random_bytes(32)

				# Curve 25519 secret clamping function
				secret[0]  = (secret[0].ord  & 0b01111111).chr
				secret[0]  = (secret[0].ord  | 0b01000000).chr
				secret[31] = (secret[31].ord & 0b11111000).chr

				@secret = secret.unpack("H*")[0].to_i(16)
			end

			@public_key = Curve25519::Base.mult(@secret)
		end

		def negotiate(other, initial_negotiation = true)
			if initial_negotiation
				other.negotiate(self, false)
			end

			shared = other.public_key.mult(@secret)

			# Bernstein uses Salsa20 as his hash
			# >	Salsa20(c0, x0, 0, x1, x2, c1, x3, 0, 0, x4, c2, x5, x6, 0, x7, c3)
			# >		(c0, c1, c2, c3) is “Curve25519output”
			# We'll just stick with sha256 since it's built in		
			hash = Digest::SHA256.new
			hash << shared.x.to_s(16)

			@keys[other.name] = hash.digest

			return nil
		end
	end
end

if __FILE__ == $PROGRAM_NAME
	# Create ECDH users alice and bob
	a = ECDH::User.new('alice')
	b = ECDH::User.new('bob')

	# alice initiates DH exchange with bob
	a.negotiate(b)

	# alice and bob now have a shared secret key
	fail "keys don't match" unless a.keys['bob'] == b.keys['alice']

	p "Success!"
end

