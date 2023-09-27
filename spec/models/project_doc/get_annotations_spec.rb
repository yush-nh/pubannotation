require 'rails_helper'

RSpec.describe ProjectDoc, type: :model do
  describe '#get_annotations' do
    let!(:doc) { create(:doc) }
    let!(:project) { create(:project) }
    let!(:project_doc) { create(:project_doc, doc: doc, project: project) }
    let(:span) { nil }
    let(:is_bag_denotations) { false }

    let!(:denotation2) { create(:object_denotation, doc: doc, project: project) }
    let!(:denotation1) { create(:denotation, doc: doc, project: project) }
    let!(:relation1) { create(:relation, hid: "S1", project: project, subj: denotation1, obj: denotation2, pred: 'predicate') }
    let!(:modification1) { create(:modification, project: project, obj: denotation1, pred: 'negation') }
    let!(:attribute1) { create(:attrivute, project: project, subj: denotation1, obj: 'Protein', pred: 'type') }

    let!(:block2) { create(:second_block, doc: doc, project: project) }
    let!(:block1) { create(:block, doc: doc, project: project) }
    let!(:relation2) { create(:relation, project: project, subj: block1, obj: block2, pred: 'next') }

    before do
      create(:modification, project: project, obj: block1, pred: 'negation')
      create(:attrivute, project: project, subj: block1, obj: 'true', pred: 'suspect')
      create(:modification, project: project, obj: relation1, pred: 'suspect')
      create(:attrivute, project: project, subj: relation1, obj: 'true', pred: 'negation')
    end

    subject { project_doc.get_annotations(span).as_json }

    it { is_expected.to be_a(Hash) }

    it { expect(subject[:project]).to eq('TestProject') }

    # Denotations are sorted by creation order
    it { expect(subject[:denotations].first).to eq(id: "T2", obj: 'object', span: { begin: 10, end: 14 }) }
    it { expect(subject[:denotations].second).to eq(id: "T1", obj: 'subject', span: { begin: 0, end: 4 }) }

    # Blocks are sorted by creation order
    it { expect(subject[:blocks].first).to eq(id: "B2", obj: '2nd line', span: { begin: 16, end: 37 }) }
    it { expect(subject[:blocks].second).to eq(id: "B1", obj: '1st line', span: { begin: 0, end: 14 }) }

    it { expect(subject[:relations].first).to eq(id: relation1.hid, pred: 'predicate', subj: 'T1', obj: 'T2') }
    it { expect(subject[:relations].second).to eq(id: relation2.hid, pred: 'next', subj: 'B1', obj: 'B2') }

    it { expect(subject[:modifications]).to include(id: modification1.hid, pred: 'negation', obj: 'T1') }
    it { expect(subject[:attributes]).to include(id: attribute1.hid, pred: 'type', subj: 'T1', obj: 'Protein') }

    context 'span is specified' do
      let(:span) { { begin: 0, end: 4 } }

      it { expect(subject[:denotations]).to include(id: "T1", obj: 'subject', span: { begin: 0, end: 4 }) }
      it { expect(subject[:blocks]).to be_nil }
      it { expect(subject[:relations]).to be_nil }
      it { expect(subject[:modifications]).to include(id: modification1.hid, pred: 'negation', obj: 'T1') }
      it { expect(subject[:attributes]).to include(id: attribute1.hid, pred: 'type', subj: 'T1', obj: 'Protein') }

      context 'no annotation among span' do
        let(:span) { { begin: 100, end: 200 } }

        it { expect(subject[:denotations]).to be_nil }
        it { expect(subject[:blocks]).to be_nil }
        it { expect(subject[:relations]).to be_nil }
        it { expect(subject[:modifications]).to be_nil }
        it { expect(subject[:attributes]).to be_nil }
      end
    end
  end
end