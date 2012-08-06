require './test_common'

class ShortestPaths
  include Bud

  state do
    table :link, [:from, :to, :cost]
    table :path, [:from, :to, :nxt, :cost]
    table :shortest, [:from, :to] => [:nxt, :cost]
    table :minmaxsumcntavg, [:from, :to] => [:mincost, :maxcost, :sumcost, :cnt, :avgcost]
    table :avrg, [:from, :to] => [:ave, :some, :kount]
    table :avrg2, [:from, :to] => [:ave, :some, :kount]
  end

  bootstrap do
    link << ['a', 'b', 1]
    link << ['a', 'b', 4]
    link << ['b', 'c', 1]
    link << ['c', 'd', 1]
    link << ['d', 'e', 1]
  end

  bloom do
    path <= link {|l| [l.from, l.to, l.to, l.cost]}
    path <= (link * path).pairs(:to => :from) do |l,p|
      [l.from, p.to, p.from, l.cost+p.cost]
    end

    # second stratum
    shortest <= path.argmin([path.from, path.to], path.cost)
    minmaxsumcntavg <= path.group([path.from, path.to], min(path.cost), max(path.cost), sum(path.cost), count, avg(path.cost))
    avrg <= path.group([:from, :to], min(:cost), max(path.cost), sum(:cost), count, avg(:cost)) do |t|
      [t[0], t[1], t[6], t[4], t[5]]
    end
    avrg2 <= path.group([:from, :to], min(:cost), max(path.cost), sum(:cost), count, avg(:cost)).rename(:chump, [:from, :to] => [:mincol, :maxcol, :sumcol, :cntcol, :avgcol]).map do |t|
        [t.from, t.to, t.avgcol, t.sumcol, t.cntcol]
    end
  end
end

class Vote
  include Bud
  state do
    scratch :vote_cnt, [:ident, :response, :cnt, :content]
    table :votes_rcvd, [:master, :peer, :ident] => [:response, :content]
  end

  bloom do
    vote_cnt <= votes_rcvd.group(
      [votes_rcvd.ident, votes_rcvd.response],
      count(votes_rcvd.peer), accum(votes_rcvd.content))
  end
end

class TiedPaths
  include Bud

  state do
    table :link, [:from, :to, :cost]
    table :path, [:from, :to, :nxt, :cost]
    table :shortest, [:from, :to] => [:nxt, :cost]
  end

  bootstrap do
    link << ['a', 'b', 1]
    link << ['a', 'b', 4]
    link << ['b', 'c', 1]
    link << ['a', 'c', 2]
  end

  bloom do
    path <= link {|e| [e.from, e.to, e.to, e.cost]}
    path <= (link*path).pairs(:to => :from) do |l,p|
      [l.from, p.to, p.from, l.cost+p.cost]
    end
    shortest <= path.argmin([path.from, path.to], path.cost).argagg(:max, [:from, :to], :nxt)
  end
end

class PriorityQ
  include Bud

  state do
    table :q, [:item] => [:priority]
    scratch :out, [:item] => [:priority]
    scratch :minny, [:priority]
    scratch :out2, [:item] => [:priority]
  end

  bootstrap do
    q << ['c', 2]
    q << ['d', 3]
    q << ['a', 1]
    q << ['b', 2]
  end

  bloom do
    # second stratum
    out <= q.argagg(:min, [], q.priority)
    minny <= q.group(nil, min(q.priority))
    q <- out

    # third stratum
    out2 <= (q * minny).matches.lefts
  end
end

class RenameGroup
  include Bud

  state do
    table :emp, [:ename, :dname] => [:sal]
    table :shoes, [:dname] => [:usualsal]
  end

  bootstrap do
    emp << ['joe', 'shoe', 10]
    emp << ['joe', 'toy', 5]
    emp << ['bob', 'shoe', 11]
  end

  bloom do
    shoes <= emp.group([:dname], avg(:sal)).rename(:tempo, [:dept] => [:avgsal]).map{|t| t if t.dept == 'shoe'}
  end
end

class JoinAgg < RenameGroup
  state do
    scratch :richsal, [:sal]
    scratch :rich, emp.key_cols => emp.val_cols
    scratch :argrich, emp.key_cols => emp.val_cols
  end

  bloom do
    richsal <= emp.group([], max(:sal))
    rich <= (richsal * emp).matches.rights
    argrich <= emp.argmax([], emp.sal)
  end
end

class AggJoin
  include Bud

  state do
    table :shoes, [:dname] => [:usualsal]
    table :emp, [:ename, :dname] => [:sal]
    scratch :funny, [:dname] => [:max_sal, :usual_sal]
  end

  bootstrap do
    emp << ['joe', 'shoe', 10]
    emp << ['joe', 'toy', 5]
    emp << ['bob', 'shoe', 11]
    shoes << ['shoe', 9]
  end

  bloom do
    funny <= (emp * shoes).matches.flatten.group([:dname], max(:sal), max(:usualsal))
  end
end

class ChoiceAgg
  include Bud

  state do
    scratch :t1
    scratch :t2
  end

  bloom do
    t1 <= [[1,1],[2,1]]
    t2 <= t1.argagg(:choose, [], :key)
  end
end

class RandAgg
  include Bud

  state do
    scratch :t1
    scratch :t2
    table :choices, [:val]
  end

  bootstrap do
    100.times {|x| t1 << [x, x+1]}
  end

  bloom do
    t2 <= t1.argagg(:choose_rand, [], :key)
    choices <= t1.group([], choose_rand(:key))
  end
end

class ChainAgg
  include Bud

  state do
    table :t1
    table :t2
    table :t3
    table :r
  end

  bootstrap do
    t1 <= [[1,1],[2,1]]
    r <= [['a', 'b']]
  end

  bloom do
    t2 <= (t1 * r * r).combos {|a,b,c| a}
    t3 <= t2.argmax([], :key)
  end
end

class BooleanAggs
  include Bud

  state do
    scratch :s1, [:x, :v]
    scratch :s2, [:v_and, :v_or]
    scratch :s3, [:x] => [:x_v_and, :x_v_or]
    table :s4, [:x, :x_v_and, :x_v_or]
  end

  bloom do
    s2 <= s1.group(nil, bool_and(:v), bool_or(:v))
    s3 <= s1.group([:x], bool_and(:v), bool_or(:v))
    s4 <= s1.group([:x], bool_and(:v), bool_or(:v))
  end
end

class TestAggs < MiniTest::Unit::TestCase
  def test_paths
    program = ShortestPaths.new
    program.tick

    program.minmaxsumcntavg.each do |t|
      assert(t[4])
      assert(t[2] <= t[3])
      assert_equal(t[4]*1.0 / t[5], t[6])
    end
    program.avrg.each do |t|
      assert_equal(t.some*1.0 / t.kount, t.ave)
    end
    program.avrg2.each do |t|
      assert_equal(t.some*1.0 / t.kount, t.ave)
    end
    program.shortest.each do |t|
      assert_equal(t[1][0].ord - t[0][0].ord, t[3])
    end
    shorts = program.shortest.map {|s| [s.from, s.to, s.cost]}
    costs = program.minmaxsumcntavg.map {|c| [c.from, c.to, c.mincost]}
    assert_equal([], shorts - costs)
  end

  def test_tied_paths
    program = TiedPaths.new
    program.tick
    assert_equal([["a", "c", "c", 2], ["b", "c", "c", 1], ["a", "b", "b", 1]].sort, program.shortest.to_a.sort)
  end

  def test_non_exemplary
    program = ShortestPaths.new
    program.tick
    assert_raises(Bud::Error) {p = program.path.argagg(:count, [program.path.from, program.path.to], nil)}
    assert_raises(Bud::Error) {p = program.path.argagg(:sum, [program.path.from, program.path.to], program.path.cost)}
    assert_raises(Bud::Error) {p = program.path.argagg(:avg, [program.path.from, program.path.to], program.path.cost)}
  end

  def test_argaggs
    program = PriorityQ.new
    program.tick
    argouts = program.out.to_a
    basicouts = program.out2.to_a
    assert_equal([], argouts - basicouts)
  end

  def test_rename
    program = RenameGroup.new
    program.tick
    shoes = program.shoes.to_a
    assert_equal([["shoe", 10.5]], shoes)
  end

  def test_join_agg
    program = JoinAgg.new
    program.tick
    assert_equal([['bob', 'shoe', 11]], program.rich.to_a)
    assert_equal([['bob', 'shoe', 11]], program.argrich.to_a)
  end

  def test_agg_join
    p = AggJoin.new
    p.tick
    assert_equal([['shoe', 11, 9]], p.funny.to_a)
  end

  def test_choice_agg
    p = ChoiceAgg.new
    p.tick
    assert(([[1,1]]) == p.t2.to_a || ([[2,1]]) == p.t2.to_a)
  end

  def test_rand_agg
    p = RandAgg.new
    p.tick
    assert(p.t1.length == 100)
    assert(p.choices.first.val >= 0)
    assert(p.choices.first.val <= 99)
    assert_equal(p.t2.first[0] + 1, p.t2.first[1])
  end

  def test_chain_agg
    p = ChainAgg.new
    assert_equal(0, p.collection_stratum("t2"))
    assert_equal(1, p.collection_stratum("t3"))
    q = Queue.new

    p.register_callback(:t3) { q.push(true) }
    p.run_bg
    q.pop
    assert_equal([[2,1]], p.t3.to_a)
  end

  def test_bool_aggs
    p = BooleanAggs.new
    p.s1 <+ [[1, true], [1, false], [2, false], [3, true]]
    p.tick
    assert_equal([[false, true]], p.s2.to_a)
    assert_equal([[1, false, true], [2, false, false], [3, true, true]],
                 p.s3.to_a.sort)
    assert_equal([[1, false, true], [2, false, false], [3, true, true]],
                 p.s4.to_a.sort)
    p.tick
    assert_equal([], p.s2.to_a)
    assert_equal([], p.s3.to_a)
    assert_equal([[1, false, true], [2, false, false], [3, true, true]],
                 p.s4.to_a.sort)
    p.s1 <+ [[1, false], [3, false]]
    p.tick
    assert_equal([[false, false]], p.s2.to_a)
    assert_equal([[1, false, false], [3, false, false]], p.s3.to_a.sort)
    assert_equal([[1, "false", "false"], [1, "false", "true"], [2, "false", "false"],
                  [3, "false", "false"], [3, "true", "true"]],
                 p.s4.to_a.map{|t| t.map{|t2| (t2 == false || t2 == true) ? t2.to_s : t2}}.sort)
  end

  class ArgminDups
    include Bud

    state do
      scratch :t1, [:a, :b, :c]
      scratch :t2, [:a, :b, :c]
      scratch :t3, [:a, :b, :c]
    end

    bloom do
      t2 <= t1.argmin([], :a)
      t3 <= t2.argmin([], :b)
    end
  end

  def test_argmin_dups
    a = ArgminDups.new
    a.t1 <= [[1, 2, 3], [5, 5, 5]]
    a.tick
    assert_equal([[1, 2, 3]], a.t2.to_a)
    assert_equal([[1, 2, 3]], a.t3.to_a)

    a.t1 <+ [[1, 2, 4], [1, 3, 5]]
    a.tick
    assert_equal([[1, 2, 4], [1, 3, 5]], a.t2.to_a.sort)
    assert_equal([[1, 2, 4]], a.t3.to_a.sort)
  end

  class SerializerTest
    include Bud

    state do
      table :buf, [:a, :b, :tstamp]
      scratch :t_in, [:a, :b]
      scratch :t_in_later, [:a, :b]
      scratch :t_out, [:a, :b]
      scratch :buf_min_time, buf.schema
      scratch :buf_min_a, buf.schema
      scratch :buf_min_b, buf.schema
    end

    bloom do
      t_in <+ t_in_later
      buf <= t_in {|i| [i.a, i.b, @budtime]}
      buf_min_time <= buf.argmin([], :tstamp)
      buf_min_a <= buf_min_time.argmin([], :a)
      buf_min_b <= buf_min_a.argmin([], :b)
      buf <- buf_min_b
      t_out <= buf_min_b {|t| [t.a, t.b]}
    end
  end

  def test_serializer
    expected = [[5, 10], [3, 2], [3, 3], [6, 6], [6, 7], [7, 1], [7, 2], [9, 1], [0, 0], [0, 1]]
    cb_cnt = 0
    s = SerializerTest.new
    s.register_callback(:t_out) do |tbl|
      e = expected[cb_cnt]
      assert_equal([e], tbl.to_a.sort)
      cb_cnt += 1
    end
    s.run_bg
    s.sync_do {
      s.t_in <+ [[5, 10]]
    }
    s.sync_do {
      s.t_in <+ [[3, 2]]
    }
    s.sync_do {
      s.t_in <+ [[7, 1], [6, 6], [6, 7], [3, 3], [7, 2], [9, 1]]
      s.t_in_later <+ [[0, 0], [0, 1]]
    }
    10.times { s.sync_do }
    assert_equal(expected.length, cb_cnt)
    s.stop
  end

  def test_vote_accum
    v = Vote.new
    v.tick
    v.sync_do {
      v.votes_rcvd <+ [["127.0.0.1:12346", "127.0.0.1:12348", 1, "yes", "vote from agent 1"]]
    }
    v.sync_do {
      v.votes_rcvd <+ [["127.0.0.1:12346", "127.0.0.1:12347", 1, "yes", "vote from agent 2"]]
    }
    assert_equal(1, v.vote_cnt.length)
    vc = v.vote_cnt.to_a.first
    assert_equal([1, "yes", 2, ["vote from agent 1", "vote from agent 2"].to_set], vc)
  end
end

class TestReduce < MiniTest::Unit::TestCase
  class ReduceTypeError
    include Bud

    state do
      table :t1
      table :t2
    end

    bootstrap { t1 <= [[5, 10]] }

    bloom do
      t2 <= t1.reduce(true) {|memo, s| true}
    end
  end

  def test_reduce_type_error
    r = ReduceTypeError.new
    assert_raises(Bud::TypeError) { r.tick }
  end

  class ReduceUnaryTuple
    include Bud

    state do
      scratch :t1, [:v, :x]
      scratch :t2, [:res]
    end

    bloom do
      # Poor man's Boolean AND
      t2 <= t1.reduce([[true]]) do |memo, t|
        if t.v == false
          [[false]]
        else
          memo
        end
      end
    end
  end

  def test_reduce_unary_tuple
    r = ReduceUnaryTuple.new
    r.tick
    assert_equal([[true]], r.t2.to_a)
    r.t1 <+ [[true, 1], [true, 2]]
    r.tick
    assert_equal([[true]], r.t2.to_a)
    r.t1 <+ [[false, 3], [true, 4]]
    r.tick
    assert_equal([[false]], r.t2.to_a)
    # Given no input in a tick, revert to default value
    r.tick
    assert_equal([[true]], r.t2.to_a)
  end
end
