import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - Lifecycle
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!    
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    private var correctAnswers = 0
    
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter = AlertPresenter()
    private let presenter = MovieQuizPresenter()
    
    private var statisticService: StatisticServiceProtocol = StatisticService()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
        setupUI()
        setupDependencies()
        startGame()
    }

    private func setupUI() {
        imageView.layer.cornerRadius = 20
    }

    private func setupDependencies() {
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
    }

    private func startGame() {
        showLoadingIndicator()
        questionFactory?.loadData()
    }

    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }

    func setButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    // MARK: - QuestionFactoryDelegate

    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        setButtonsEnabled(true)
    }
    
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            let text = """
            Ваш результат: \(correctAnswers)/10
            Количество сыгранных квизов: \(statisticService.gamesCount) 
            Рекорд: \(statisticService.bestGame.correct)/10 (\(statisticService.bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
            """
          let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: text,
            buttonText: "Сыграть ещё раз")
          show(quiz: viewModel)
          imageView.layer.borderWidth = 0
      } else {
          presenter.switchToNextQuestion()
        
          self.questionFactory?.requestNextQuestion()
      }
    }

    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText) { [weak self] in
            guard let self else { return }
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            questionFactory?.requestNextQuestion()
        }
        alertPresenter.presentAlert(in: self, model: alertModel)
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз") {[weak self] in
                guard let self else { return }
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                questionFactory?.requestNextQuestion()
            }
        alertPresenter.presentAlert(in: self, model: model)
    }
    private func hideLoadingIndicator(){
        activityIndicator.isHidden = true
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
}
