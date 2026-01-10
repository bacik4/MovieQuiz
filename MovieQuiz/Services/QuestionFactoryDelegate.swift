//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//
protocol QuestionFactoryDelegate: AnyObject{
    func didReceiveNextQuestion(question: QuizQuestion?)
}
