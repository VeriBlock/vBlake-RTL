module mix_vg(
  input clk,
  input [63:0] a_i,
  input [63:0] b_i,
  input [63:0] c_i,
  input [63:0] d_i,
  input [63:0] m0,
  input [63:0] m1,
  output [63:0] a_o,
  output [63:0] b_o,
  output [63:0] c_o,
  output [63:0] d_o
);

logic [63:0] b_i_p1;
logic [63:0] c_i_p1;

logic [63:0] m1_p1, m1_p2, m1_p3, m1_p4;

logic [63:0] a0_p0, a0_p1, a0_p2, a1_p2, a1_p3, a1_p4, a1_p5;
logic [63:0] b0_p1, b0_p2, b0_p3, b1_p3, b1_p4, b1_p5;
logic [63:0] c0_p1, c0_p2, c0_p3, c1_p3, c1_p4, c1_p5;
logic [63:0] d0_p0, d0_p1, d0_p2, d1_p2, d1_p3, d1_p4, d2_p3, d2_p4, d2_p5;

always_comb begin
  // v[a] = v[a] + v[b] + (x ^ c1);
  a0_p0 = a_i + b_i + m0;
  // v[d] ^= v[a];
  d0_p0 = d_i ^ a0_p0;
  // v[d] = ROTR64(v[d], 60);
  d0_p0 = {d0_p0[59:0], d0_p0[63:60]};
end

// 1
always_ff @ (posedge clk) begin
  a0_p1 <= a0_p0;
  d0_p1 <= d0_p0;
  b_i_p1 <= b_i;
  c_i_p1 <= c_i;
end

always_comb begin
  // v[c] = v[c] + v[d];
  c0_p1 = c_i_p1 + d0_p1;
  // v[b] = ROTR64(v[b] ^ v[c], 43);
  b0_p1 = b_i_p1 ^ c0_p1;
  // v[b] = ROTR64(v[b] ^ v[c], 43);
  b0_p1 = {b0_p1[42:0], b0_p1[63:43]};
end

// 2
always_ff @ (posedge clk) begin
  m1_p1 <= m1;
  m1_p2 <= m1_p1;
  a0_p2 <= a0_p1;
  b0_p2 <= b0_p1;
  c0_p2 <= c0_p1;
  d0_p2 <= d0_p1;
end

always_comb begin
  // v[a] = v[a] + v[b] + (y ^ c2);
  a1_p2 = a0_p2 + b0_p2 + m1_p2;
  // v[d] = ROTR64(v[d] ^ v[a], 5);
  d1_p2 = d0_p2 ^ a1_p2;
  d1_p2 = {d1_p2[4:0], d1_p2[63:5]};
end

// 3
always_ff @ (posedge clk) begin
  a1_p3 <= a1_p2;
  b0_p3 <= b0_p2;
  c0_p3 <= c0_p2;
  d1_p3 <= d1_p2;
end

always_comb begin
  // v[c] = v[c] + v[d];
  c1_p3 = c0_p3 + d1_p3;
  // v[b] = ROTR64(v[b] ^ v[c], 18);
  b1_p3 = b0_p3 ^ c1_p3;
  b1_p3 = {b1_p3[17:0], b1_p3[63:18]};
//  d2_p3 = d1_p3 ^ ((~a1_p3 & ~b1_p3 & ~c1_p3) | (~a1_p3 & b1_p3 & c1_p3) |
//             (a1_p3 & ~b1_p3 & c1_p3) | (a1_p3 & b1_p3 & ~c1_p3));
end

// 4
always_ff @ (posedge clk) begin
  a1_p4 <= a1_p3;
  b1_p4 <= b1_p3;
  c1_p4 <= c1_p3;
  d1_p4 <= d1_p3;
end

always_comb begin
  // X'Y'Z' + X'YZ + XY'Z + XYZ'    LUT: 10010110
  //  v[d] ^= (~v[a] & ~v[b] & ~v[c]) | (~v[a] & v[b] & v[c]) |
  //          (v[a] & ~v[b] & v[c])   | (v[a] & v[b] & ~v[c]);
  d2_p4 = d1_p4 ^ ((~a1_p4 & ~b1_p4 & ~c1_p4) | (~a1_p4 & b1_p4 & c1_p4) |
                   (a1_p4 & ~b1_p4 & c1_p4) | (a1_p4 & b1_p4 & ~c1_p4));
end

// 5
always_ff @ (posedge clk) begin
  a1_p5 <= a1_p4;
  b1_p5 <= b1_p4;
  c1_p5 <= c1_p4;
  d2_p5 <= d2_p4;
end

// X'Y'Z + X'YZ' + XY'Z' + XYZ    LUT: 01101001
//  v[d] ^= (~v[a] & ~v[b] & v[c]) | (~v[a] & v[b] & ~v[c]) |
//          (v[a] & ~v[b] & ~v[c]) | (v[a] & v[b] & v[c]);
assign d_o = d2_p5 ^ ((~a1_p5 & ~b1_p5 & c1_p5) | (~a1_p5 & b1_p5 & ~c1_p5) |
                      (a1_p5 & ~b1_p5 & ~c1_p5) | (a1_p5 & b1_p5 & c1_p5));

//assign d_o = d2_p4 ^ ((~a1_p4 & ~b1_p4 & c1_p4) | (~a1_p4 & b1_p4 & ~c1_p4) |
//                      (a1_p4 & ~b1_p4 & ~c1_p4) | (a1_p4 & b1_p4 & c1_p4));

//assign d_o = d2_p3 ^ ((~a1_p3 & ~b1_p3 & c1_p3) | (~a1_p3 & b1_p3 & ~c1_p3) |
//                   (a1_p3 & ~b1_p3 & ~c1_p3) | (a1_p3 & b1_p3 & c1_p3));


// (XYZ' + X' YZ  + Z XY'  + X' Y' Z') ^ (X'Y'Z + X'YZ' + XY'Z' + XYZ) ;
// X XY  + XYZ' X Z  + XYZ X Z'  + XYZ YZ' Z XY  + XYZ' YZ Z' XY  + XYZ' YZ Z Y + XYZ YZ' Z' Y;

//assign d_o = (a1_p4 & a1_p4 & b1_p4)  |
//             (a1_p4 & b1_p4 & ~c1_p4 & a1_p4 & c1_p4) |
//             (a1_p4 & b1_p4 & c1_p4 & a1_p4 & ~c1_p4)  |
//             (a1_p4 & b1_p4 & c1_p4 & b1_p4 & ~c1_p4 & c1_p4 & a1_p4 & b1_p4) |
//             (a1_p4 & b1_p4 & ~c1_p4 & b1_p4 & c1_p4 & ~c1_p4 & a1_p4 & b1_p4) |
//             (a1_p4 & b1_p4 & ~c1_p4 & b1_p4 & c1_p4 & c1_p4 & b1_p4) |
//             (a1_p4 & b1_p4 & c1_p4 & b1_p4 & ~c1_p4 & ~c1_p4 & b1_p4);

assign a_o = a1_p5;
assign b_o = b1_p5;
assign c_o = c1_p5;

endmodule
