//
//  ExamContext.swift
//  001DK
//

import SwiftUI
import Combine

class ExamContext: ObservableObject {
    @Published var examType: ExamType
    @AppStorage("selectedExamType") private var savedExam: String = ""

    init(examType: ExamType) {
        self.examType = examType
    }

    func switchExam(to exam: ExamType) {
        examType = exam
        savedExam = exam.rawValue
    }
}
