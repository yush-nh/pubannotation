require 'test_helper'

class InstantiateAndSaveAnnotationsCollectionTest < ActiveSupport::TestCase
  setup do
    @project = projects(:one)
  end

  test "update to empty annotations" do
    current = Time.zone.local(2022, 7, 11, 10, 04, 44)
    travel_to current do
      InstantiateAndSaveAnnotationsCollection.call @project, []
    end

    @project.reload
    assert_equal 0, @project.denotations_num
    assert_equal 0, @project.relations_num
    assert_equal 0, @project.modifications_num
    assert_equal current, @project.updated_at
    assert_equal current, @project.annotations_updated_at

    # Confirm imported annotations
    assert_not Denotation.exists?
    assert_not Relation.exists?
    assert_not Attrivute.exists?
    assert_not Modification.exists?
  end

  test "update to non-empty annotations" do
    current = Time.zone.local(2022, 7, 11, 10, 04, 44)
    travel_to current do
      annotations_collection = [{ sourcedb: "test_db", sourceid: "1234",
                                  denotations: [
                                    { id: "d1", span: { begin: 1, end: 2 }, obj: "A" },
                                    { id: "d2", span: { begin: 100, end: 200 }, obj: "B" }
                                  ],
                                  relations: [
                                    { id: "r1", pred: "C", subj: "d1", obj: "d2" },
                                    { id: "r2", pred: "C", subj: "d2", obj: "d1" }
                                  ],
                                  attributes: [
                                    { id: "a1", pred: "D", obj: "E", subj: "d1" },
                                    { id: "a2", pred: "D", obj: "E", subj: "d2" }
                                  ],
                                  modifications: [
                                    { id: "m1", pred: "F", obj: "d1" },
                                    { id: "m2", pred: "G", obj: "d1" }
                                  ]
                                }]
      InstantiateAndSaveAnnotationsCollection.call @project, annotations_collection
    end

    @project.reload
    assert_equal 2, @project.denotations_num
    assert_equal 2, @project.relations_num
    assert_equal 2, @project.modifications_num
    assert_equal current, @project.updated_at
    assert_equal current, @project.annotations_updated_at

    # Confirm imported annotations
    assert_equal 'd1', Denotation.first.hid
    assert_equal 1, Denotation.first.begin
    assert_equal 2, Denotation.first.end
    assert_equal 'A', Denotation.first.obj
    assert_equal 'd2', Denotation.second.hid
    assert_equal 'r1', Relation.first.hid
    assert_equal 'C', Relation.first.pred
    assert_equal Denotation.first, Relation.first.subj
    assert_equal Denotation.second, Relation.first.obj
    assert_equal 'r2', Relation.second.hid
    assert_equal 'a1', Attrivute.first.hid
    assert_equal 'D', Attrivute.first.pred
    assert_equal 'E', Attrivute.first.obj
    assert_equal Denotation.first, Attrivute.first.subj
    assert_equal 'a2', Attrivute.second.hid
    assert_equal 'm1', Modification.first.hid
    assert_equal 'F', Modification.first.pred
    assert_equal Denotation.first, Modification.first.obj
    assert_equal 'm2', Modification.second.hid
  end
end
