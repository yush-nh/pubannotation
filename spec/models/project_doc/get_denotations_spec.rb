require 'rails_helper'

RSpec.describe ProjectDoc, type: :model do
  describe 'get_denotations' do
    subject { project_doc.get_denotations(span, context_size, sort) }

    let(:doc) { create(:doc) }
    let(:project) { create(:project) }
    let(:project_doc) { create(:project_doc, doc: doc, project: project) }
    let(:span) { nil }
    let(:context_size) { nil }
    let(:sort) { false }

    it 'returns an array' do
      is_expected.to be_a(ActiveRecord::AssociationRelation)
    end

    context 'when there are no denotations' do
      it { is_expected.to be_empty }
    end

    context 'when there are denotations' do
      before do
        create(:denotation, doc: doc, project: project)
        create(:object_denotation, doc: doc, project: project)
        create(:verb_denotation, doc: doc, project: project)
      end

      it { is_expected.not_to be_empty }

      it 'returns an array of denotations' do
        expect(subject.first).to be_a(Denotation)
      end

      it 'return an array of denotations sorted by creation order' do
        expect(subject.second.hid).to eq('T2')
        expect(subject.third.hid).to eq('T3')
      end

      context 'when span is specified' do
        let(:span) { {begin: 8, end: 14} }
        let(:object_denotation) { Denotation.find_by(hid: 'T2') }

        it 'returns an array of denotations between the specified span' do
          expect(subject.first.hid).to eq(object_denotation.hid)
        end

        it 'returns an array of denotations offset by the specified span' do
          expect(subject.first.begin).to eq(object_denotation.begin - span[:begin])
          expect(subject.first.end).to eq(object_denotation.end - span[:begin])
        end

        context 'when context_size is specified' do
          let(:context_size) { 6 }

          it 'returns an array of denotations offset by the specified span and context_size' do
            expect(subject.first.begin).to eq(object_denotation.begin - span[:begin] + context_size)
            expect(subject.first.end).to eq(object_denotation.end - span[:begin] + context_size)
          end

          context 'when context_size equals to begin of the span' do
            let(:context_size) { 8 }

            it 'returns an array of denotations without offset' do
              expect(subject.first.begin).to eq(object_denotation.begin)
              expect(subject.first.end).to eq(object_denotation.end)
            end
          end

          context 'when context_size is bigger than begin of the span' do
            let(:context_size) { 10 }

            it 'returns an array of denotations without offset' do
              expect(subject.first.begin).to eq(object_denotation.begin)
              expect(subject.first.end).to eq(object_denotation.end)
            end
          end
        end
      end

      context 'when sort is specified' do
        let(:sort) { true }

        it 'return an array of denotations sorted by begin' do
          expect(subject.second.hid).to eq('T3')
          expect(subject.third.hid).to eq('T2')
        end
      end
    end
  end
end