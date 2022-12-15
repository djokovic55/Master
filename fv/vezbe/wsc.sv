module wsc
  ( input        clk,
    input        rst,
    input        wolf,
    input        sheep,
    input        cab,
    output [3:0] state);

    logic w, s, c, t;
    always @ (posedge clk)
      if (rst)
        begin
	    w <= 1'b0;
	    s <= 1'b0;
	    c <= 1'b0;
	    t <= 1'b0;
	end
      else
        begin
	    t <= ~ t;
	    if (wolf)
	      w <= ~w;
	    if (sheep)
	      s <= ~s;
	    if (cab)
	      c <= ~c;
	end

    assign state = {t, w, s, c};
    wire [2:0] in3 = {wolf, sheep, cab};

    default clocking
        @(posedge clk);
    endclocking

    default disable iff (rst);

    assume_valid_input :
      assume property ((in3 == 3'b000) | (in3 == 3'b001) |
                       (in3 == 3'b010) | (in3 == 3'b100));

    assume_wolf_sheep :
      restrict property (~((t & ~w & ~s) | (~t & w & s)));

    assume_sheep_cab :
      restrict property (~((t & ~s & ~c) | (~t & s & c)));

        property same_side(a, b, c);
            a |-> (b == c);
        endproperty

    assume_ss_cab :
      restrict property (same_side(cab, c, t));

    assume_ss_wolf :
      restrict property (same_side(wolf, w, t));

    assume_ss_sheep :
      restrict property (same_side(sheep, s, t));

    cov_main: cover property (state == 4'b1111);
endmodule
