# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe DifferentiationTag::OverrideConverterService do
  describe "convert_tags_to_adhoc_overrides_for" do
    before(:once) do
      @course = course_model

      @teacher = teacher_in_course(course: @course, active_all: true).user
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
      @student3 = student_in_course(course: @course, active_all: true).user
    end

    let(:service) { DifferentiationTag::OverrideConverterService }

    def enable_differentiation_tags_for_context
      @course.account.enable_feature!(:assign_to_differentiation_tags)
      @course.account.settings[:allow_assignment_to_differentiation_tags] = { value: true }
      @course.account.save!
    end

    def create_diff_tag_override_for_module(context_module, tag)
      context_module.assignment_overrides.create!(set_type: "Group", set: tag)
    end

    context "validate parameters" do
      before do
        @module = @course.context_modules.create!
      end

      it "raises an error if learning object is not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: nil, course: @course, executing_user: @teacher)
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if the learning object type is not supported" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: @course, course: @course, executing_user: @teacher)
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if course is not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: nil, executing_user: @teacher)
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "raises multiple errors if learning object and course are not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: nil, course: nil, executing_user: @teacher)
        expect(errors.count).to eq(2)
        expect(errors[0]).to eq("Invalid course provided")
        expect(errors[1]).to eq("Invalid learning object provided")
      end
    end

    context "convert tags to adhoc overrides" do
      before do
        enable_differentiation_tags_for_context
        @diff_tag_category = @course.group_categories.create!(name: "Learning Level", non_collaborative: true)
        @diff_tag1 = @course.groups.create!(name: "Honors", group_category: @diff_tag_category, non_collaborative: true)
        @diff_tag2 = @course.groups.create!(name: "Standard", group_category: @diff_tag_category, non_collaborative: true)

        # Place student 1 in "honors" learning level
        @diff_tag1.add_user(@student1, "accepted")

        @diff_tag2.add_user(@student2, "accepted")
        @diff_tag2.add_user(@student3, "accepted")
      end

      context "context modules" do
        before do
          @module = @course.context_modules.create!
        end

        it "converts tag overrides to adhoc overrides" do
          create_diff_tag_override_for_module(@module, @diff_tag1)
          create_diff_tag_override_for_module(@module, @diff_tag2)

          expect(@module.assignment_overrides.active.count).to eq(2)
          expect(@module.assignment_overrides.active.where(set_type: "Group").count).to eq(2)

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(1)
          override = @module.assignment_overrides.active.first
          expect(override.set_type).to eq("ADHOC")
          expect(override.assignment_override_students.count).to eq(3)
        end

        it "always creates a new adhoc override even if one alread exists" do
          adhoc_override = @module.assignment_overrides.create!(set_type: "ADHOC")
          adhoc_override.assignment_override_students.create!(user: @student1)

          create_diff_tag_override_for_module(@module, @diff_tag1)
          create_diff_tag_override_for_module(@module, @diff_tag2)

          expect(@module.assignment_overrides.active.count).to eq(3)

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(2)
          expect(@module.assignment_overrides.active.where(set_type: "ADHOC").count).to eq(2)
        end

        it "removes tag override even if no students are in the tag" do
          diff_tag3 = @course.groups.create!(name: "No Students", group_category: @diff_tag_category, non_collaborative: true)
          create_diff_tag_override_for_module(@module, diff_tag3)

          expect(@module.assignment_overrides.active.count).to eq(1)

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(0)
        end

        it "does nothing if no differentiation tag overrides exist" do
          @module.assignment_overrides.create!(set_type: "Course", set: @course)

          expect(@module.assignment_overrides.active.count).to eq(1)

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(1)
        end

        it "ignores soft-deleted differentiation tag overrides" do
          create_diff_tag_override_for_module(@module, @diff_tag1)
          create_diff_tag_override_for_module(@module, @diff_tag2)

          # soft-delete one of the tag overrides
          tag_overrides = @module.assignment_overrides.active.where(set_type: "Group")
          tag_overrides.first.destroy

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(1)
          override = @module.assignment_overrides.active.first
          expect(override.set_type).to eq("ADHOC")
          expect(override.assignment_override_students.count).to eq(2)
        end

        it "successful when all students in diff tag already have ADHOC overrides" do
          create_diff_tag_override_for_module(@module, @diff_tag2)

          adhoc_override = @module.assignment_overrides.create!(set_type: "ADHOC")
          adhoc_override.assignment_override_students.create!(user: @student2)
          adhoc_override.assignment_override_students.create!(user: @student3)

          expect(@module.assignment_overrides.active.count).to eq(2)

          service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course, executing_user: @teacher)

          expect(@module.assignment_overrides.active.count).to eq(1)
        end
      end
    end
  end
end
