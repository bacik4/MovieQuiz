
import Foundation

final class MovieQuizPresenter: QuestionFactoryDelegate {

    // MARK: - Constants

    private let questionsAmount: Int = 10

    // MARK: - Dependencies

    private var questionFactory: QuestionFactoryProtocol?
    private var statisticService: StatisticServiceProtocol = StatisticService()
    weak var viewController: MovieQuizViewControllerProtocol?

    // MARK: - State

    private var currentQuestion: QuizQuestion?
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0

    // MARK: - Initialization

    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        setupDependencies()
        viewController.showLoadingIndicator()
        questionFactory?.loadData()
    }

    // MARK: - Public API

    func startGame() {
        viewController?.showLoadingIndicator()
        questionFactory?.loadData()
    }

    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }

    func yesButtonClicked() {
        handleAnswer(true)
    }

    func noButtonClicked() {
        handleAnswer(false)
    }

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    func makeResultsMessage() -> String {
        statisticService.store(correct: correctAnswers, total: questionsAmount)

        let bestGame = statisticService.bestGame

        let currentGameResultLine =
            "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        let totalPlaysCountLine =
            "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let bestGameInfoLine =
            "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine =
            "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"

        return [
            currentGameResultLine,
            totalPlaysCountLine,
            bestGameInfoLine,
            averageAccuracyLine
        ].joined(separator: "\n")
    }

    // MARK: - QuestionFactoryDelegate

    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        viewController?.showNetworkError(message: error.localizedDescription)
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }

        currentQuestion = question
        let viewModel = convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func setupDependencies() {
       statisticService = StatisticService()
       questionFactory = QuestionFactory(
           moviesLoader: MoviesLoader(),
           delegate: self
       )
   }

    // MARK: - Private logic

    private func handleAnswer(_ givenAnswer: Bool) {
        guard let currentQuestion else { return }

        viewController?.setButtonsEnabled(false)

        let isCorrect = givenAnswer == currentQuestion.correctAnswer
        proceedWithAnswer(isCorrect: isCorrect)
    }

    private func proceedWithAnswer(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }

        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.proceedToNextQuestionOrResults()
        }
    }

    private func proceedToNextQuestionOrResults() {
        if isLastQuestion() {
            let resultViewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: makeResultsMessage(),
                buttonText: "Сыграть ещё раз"
            )
            viewController?.show(quiz: resultViewModel)
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }

    private func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
}
