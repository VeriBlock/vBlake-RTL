module vblake_hash(
  input         clk,
  input logic [511:0] hash_input_data,
  output logic [63:0] hash_output_data
);

localparam logic [63:0] vblake_c[0:15] = {
  64'ha51b6a89d489e800, 64'hd35b2e0e0b723800,
  64'ha47b39a2ae9f9000, 64'h0c0efa33e77e6488,
  64'h4f452fec309911eb, 64'h3cfcc66f74e1022c,
  64'h4606ad364dc879dd, 64'hbba055b53d47c800,
  64'h531655d90c59eb1b, 64'hd1a00ba6dae5b800,
  64'h2fe452da9632463e, 64'h98a7b5496226f800,
  64'hbafcd004f92ca000, 64'h64a39957839525e7,
  64'hd859e6f081aae000, 64'h63d980597b560e6b
};

localparam logic [63:0] state_iv[0:15] = {
    64'h4bbf42c1f107ad85,
    64'h5d11a8c3b5aeb12e,
    64'ha64ab78dc2774652,
    64'hc67595724658f253,
    64'hb8864e79cb891e56,
    64'h12ed593e29fb41a1,
    64'hb1da3ab63c60baa8,
    64'h6d20e50c1f954ded,
    64'h4bbf42c1f006ad9d,
    64'h5d11a8c3b5aeb12e,
    64'ha64ab78dc2774652,
    64'hc67595724658f253,
    64'hb8864e79cb891e16,
    64'h12ed593e29fb41a1,
    64'h4e25c549c39f4557,
    64'h6d20e50c1f954ded
};

localparam logic [3:0] sigma_x[0:9][0:15] = '{
'{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
'{14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3},
'{11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4},
'{7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8},
'{9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13},
'{2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9},
'{12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11},
'{13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10},
'{6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5},
'{10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0}};

genvar x;
generate
for (x = 0; x < 16; x++) begin : vblake_g
  logic [63:0] data_a_p0[0:15];
  logic [63:0] data_a_p1[0:15];
  logic [63:0] data_a_p2[0:15];
  logic [63:0] data_a_p3[0:15];
  logic [63:0] data_a_p4[0:15];
  //(* srl_style = "srl" *) logic [63:0] data_a_p4[0:15];
  (* srl_style = "srl_reg" *) logic [63:0] data_a_p5[0:15];

  logic [63:0] data_b_p0[0:15];
  logic [63:0] data_b_p1[0:15];
  logic [63:0] data_b_p2[0:15];
  logic [63:0] data_b_p3[0:15];
  logic [63:0] data_b_p4[0:15];
  //(* srl_style = "srl" *) logic [63:0] data_b_p4[0:15];
  (* srl_style = "srl_reg" *) logic [63:0] data_b_p5[0:15];

  logic [63:0] state_a[0:15];
  logic [63:0] state_b[0:15];

  if (x == 0) begin
    always_comb begin
      data_a_p0 = {
        hash_input_data[511:448],
        hash_input_data[447:384],
        hash_input_data[383:320],
        hash_input_data[319:256],
        hash_input_data[255:192],
        hash_input_data[191:128],
        hash_input_data[127:64],
        hash_input_data[63:0],
        64'b0,
        64'b0,
        64'b0,
        64'b0,
        64'b0,
        64'b0,
        64'b0,
        64'b0
      };
    end
  end else begin
    always_comb begin
      data_a_p0 = vblake_g[x - 1].data_b_p5;
    end
  end

  always_comb begin
    data_b_p0 = data_a_p5;
  end

  always_ff @ (posedge clk) begin
    data_a_p1 <= data_a_p0;
    data_a_p2 <= data_a_p1;
    data_a_p3 <= data_a_p2;
    data_a_p4 <= data_a_p3;
    data_a_p5 <= data_a_p4;

    data_b_p1 <= data_b_p0;
    data_b_p2 <= data_b_p1;
    data_b_p3 <= data_b_p2;
    data_b_p4 <= data_b_p3;
    data_b_p5 <= data_b_p4;
  end

  genvar i;
  for (i = 0; i < 4; i++) begin : mix_vg_g
    if (x == 0) begin
      mix_vg mix_vg_i(
        .clk(clk),
        .a_i(state_iv[i]),
        .b_i(state_iv[i + 4]),
        .c_i(state_iv[i + 8]),
        .d_i(state_iv[i + 12]),
        .m0(data_a_p0[sigma_x[x % 10][2 * i + 1]] ^ vblake_c[sigma_x[x % 10][2 * i + 1]]),
        .m1(data_a_p0[sigma_x[x % 10][2 * i]] ^ vblake_c[sigma_x[x % 10][2 * i]]),
        .a_o(state_a[i]),
        .b_o(state_a[i + 4]),
        .c_o(state_a[i + 8]),
        .d_o(state_a[i + 12])
      );
    end else begin
      mix_vg mix_vg_i(
        .clk(clk),
        .a_i(vblake_g[x - 1].state_b[i]),
        .b_i(vblake_g[x - 1].state_b[i + 4]),
        .c_i(vblake_g[x - 1].state_b[i + 8]),
        .d_i(vblake_g[x - 1].state_b[i + 12]),
        .m0(data_a_p0[sigma_x[x % 10][2 * i + 1]] ^ vblake_c[sigma_x[x % 10][2 * i + 1]]),
        .m1(data_a_p0[sigma_x[x % 10][2 * i]] ^ vblake_c[sigma_x[x % 10][2 * i]]),
        .a_o(state_a[i]),
        .b_o(state_a[i + 4]),
        .c_o(state_a[i + 8]),
        .d_o(state_a[i + 12])
      );
    end
  end

  mix_vg mix_vg_4(
    .clk(clk),
    .a_i(state_a[0]),
    .b_i(state_a[5]),
    .c_i(state_a[10]),
    .d_i(state_a[15]),
    .m0(data_b_p0[sigma_x[x % 10][9]] ^ vblake_c[sigma_x[x % 10][9]]),
    .m1(data_b_p0[sigma_x[x % 10][8]] ^ vblake_c[sigma_x[x % 10][8]]),
    .a_o(state_b[0]),
    .b_o(state_b[5]),
    .c_o(state_b[10]),
    .d_o(state_b[15])
  );

  mix_vg mix_vg_5(
    .clk(clk),
    .a_i(state_a[1]),
    .b_i(state_a[6]),
    .c_i(state_a[11]),
    .d_i(state_a[12]),
    .m0(data_b_p0[sigma_x[x % 10][11]] ^ vblake_c[sigma_x[x % 10][11]]),
    .m1(data_b_p0[sigma_x[x % 10][10]] ^ vblake_c[sigma_x[x % 10][10]]),
    .a_o(state_b[1]),
    .b_o(state_b[6]),
    .c_o(state_b[11]),
    .d_o(state_b[12])
  );

  mix_vg mix_vg_6(
    .clk(clk),
    .a_i(state_a[2]),
    .b_i(state_a[7]),
    .c_i(state_a[8]),
    .d_i(state_a[13]),
    .m0(data_b_p0[sigma_x[x % 10][13]] ^ vblake_c[sigma_x[x % 10][13]]),
    .m1(data_b_p0[sigma_x[x % 10][12]] ^ vblake_c[sigma_x[x % 10][12]]),
    .a_o(state_b[2]),
    .b_o(state_b[7]),
    .c_o(state_b[8]),
    .d_o(state_b[13])
  );

  mix_vg mix_vg_7(
    .clk(clk),
    .a_i(state_a[3]),
    .b_i(state_a[4]),
    .c_i(state_a[9]),
    .d_i(state_a[14]),
    .m0(data_b_p0[sigma_x[x % 10][15]] ^ vblake_c[sigma_x[x % 10][15]]),
    .m1(data_b_p0[sigma_x[x % 10][14]] ^ vblake_c[sigma_x[x % 10][14]]),
    .a_o(state_b[3]),
    .b_o(state_b[4]),
    .c_o(state_b[9]),
    .d_o(state_b[14])
  );

  if (x == 15) begin
    always_ff @ (posedge clk) begin
      hash_output_data <= 64'h3C10ED058B3FE57E ^ state_b[0] ^ state_b[8] ^
                          state_b[3] ^ state_b[11] ^ state_b[6] ^ state_b[14];
    end
  end
end

endgenerate
endmodule
