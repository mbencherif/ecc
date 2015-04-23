
A = 0
B = 17

# infty = (0,1,0)

def add(x1, y1, x2, y2)
	if x1 == 0 && y1 == 1
		return x2, y2
	elsif x2 == 0 && y2 == 1
		return x1, y1
	elsif x1 == x2 && y1 == y2
		return double(x1,y1)
	elsif x1 == x2 && y1 != y2
		return 0, 1
	end

	x3 = (y2-y1)**2 / (x2-x1)**2 - x1 - x2
	y3 = ((2*x1 + x2)*(y2-y1))/(x2-x1) - ((y2-y1)**3)/((x2-x1)**3) - y1
	return x3, y3
end

def double(x1, y1)
	if x1 == 0 && y1 == 1
		return 0, 1
	end

	x2 = ((3*x1**2 + A)**2)/((2*y1)**2) - 2*x1
	y2 = (3*x1*(3*x1**2 + A))/(2*y1) - ((3*x1^2+A)**3)/((2*y1)**3) - y1
	return x2, y2
end

def mult(n, x1, y1)
	if n == 0
		return 0,1
	elsif n == 1
		return x1, y1 
	elsif n < 0
		return mult(-n, x1, -y1)
	end

	x,y = 0, 1

	n.to_s(2).split("").each do |bit|
		x, y = double(x,y)
		if bit == "1"
			x, y = add(x, y, x1, y1)	
		end
	end

	return x,y
end

P1 = [-2,3]
P2 = [-1,4]
P3 = [2,5]
P4 = [4,9]
P5 = [8,23]

Points = [P1, P2, P3, P4, P5]

bounds = -5..5

if __FILE__ == $PROGRAM_NAME
	bounds.each do |m|
		bounds.each do |n|
			#p "(#{m},#{n})"

			begin
				x1, y1 = mult(m, P1[0], P1[1])
				x2, y2 = mult(n, P3[0], P3[1])
				x3, y3 = add(x1, y1, x2, y2)
			rescue ZeroDivisionError => e
				p e
			end

			if Points.include? [x3, y3]
				p "Point (#{x3},#{y3}) = #{m}P1 + #{n}P3"
				Points.delete([x3,y3])
			end
		end
	end
end