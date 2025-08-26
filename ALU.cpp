#include <systemc>
using namespace sc_core;
using namespace sc_dt;


static const int W = 32;                   
enum Op : sc_uint<5> {                    
  OP_ADD  = 0,
  OP_SUB  = 1,
  OP_AND  = 2,
  OP_OR   = 3,
  OP_XOR  = 4,
  OP_SLL  = 5,
  OP_SRL  = 6,   
  OP_SRA  = 7,  
  OP_SLT  = 8,   
  OP_SLTU = 9,   
};

SC_MODULE(ALU) {

  sc_in<sc_uint<W>>  a{"a"};
  sc_in<sc_uint<W>>  b{"b"};
  sc_in<sc_uint<5>>  op{"op"};

  sc_out<sc_uint<W>> result{"result"};
  sc_out<bool>       z{"z"}; 
  sc_out<bool>       n{"n"}; 
  sc_out<bool>       c{"c"}; 
  sc_out<bool>       v{"v"}; 

  
  void do_alu() {
    sc_uint<W>  res = 0;
    bool        Z = false, N = false, C = false, V = false;

    const sc_uint<W> ua = a.read();
    const sc_uint<W> ub = b.read();
    const sc_int<W>  sa = (sc_int<W>)ua;
    const sc_int<W>  sb = (sc_int<W>)ub;
    const sc_uint<5> shamt = ub.range(4,0);

    switch ((Op)op.read()) {
      case OP_ADD: {
        sc_uint<W+1> tmp = (sc_uint<W+1>)ua + (sc_uint<W+1>)ub;
        res = tmp.range(W-1,0);
        C   = tmp[W];
       
        bool sign_a = ua[W-1], sign_b = ub[W-1], sign_r = res[W-1];
        V = (sign_a == sign_b) && (sign_r != sign_a);
        break;
      }
      case OP_SUB: {
        sc_uint<W+1> tmp = (sc_uint<W+1>)ua - (sc_uint<W+1>)ub;
        res = tmp.range(W-1,0);
        C   = tmp[W];
        
        bool sign_a = ua[W-1], sign_b = ub[W-1], sign_r = res[W-1];
        V = (sign_a != sign_b) && (sign_r != sign_a);
        break;
      }
      case OP_AND:  res = ua & ub; break;
      case OP_OR:   res = ua | ub; break;
      case OP_XOR:  res = ua ^ ub; break;

      case OP_SLL:  res = ua << shamt; break;
      case OP_SRL:  res = ua >> shamt; break;
      case OP_SRA:  res = (sc_uint<W>)((sc_int<W>)sa >> shamt); break;

      case OP_SLT:  res = (sa < sb) ? 1 : 0; break;
      case OP_SLTU: res = (ua < ub) ? 1 : 0; break;     


      default: res = 0; break;
    }

    Z = (res == 0);
    N = res[W-1];

    result.write(res);
    z.write(Z);
    n.write(N);
    c.write(C);
    v.write(V);
  }

  SC_CTOR(ALU) {
    SC_METHOD(do_alu);
    sensitive << a << b << op;  
    dont_initialize();
  }
};

