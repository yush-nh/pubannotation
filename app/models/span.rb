class Span < ActiveRecord::Base
  belongs_to :project
  belongs_to :doc

  has_many :insanns, :foreign_key => "insobj_id", :dependent => :destroy

  has_many :subrels, :class_name => 'Relation', :as => :relsub, :dependent => :destroy
  has_many :objrels, :class_name => 'Relation', :as => :relobj, :dependent => :destroy

  has_many :insmods, :class_name => 'Modification', :through => :insanns
  has_many :relmods, :class_name => 'Modification', :through => :relantions


  attr_accessible :hid, :begin, :end, :category

  validates :hid,       :presence => true
  validates :begin,     :presence => true
  validates :end,       :presence => true
  validates :category,  :presence => true
  validates :project_id, :presence => true
  validates :doc_id,    :presence => true

  def get_hash
    hspan = Hash.new
    hspan[:id]       = hid
    hspan[:span]     = {:begin => self.begin, :end => self.end}
    hspan[:category] = category
    hspan
  end
end
