#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLineEdit>
#include <QStandardItemModel>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

public:
    void createUi();

private Q_SLOTS:
    void slotClicked();
    void slotDoubleClicked(const QModelIndex &index);

private:
    QLineEdit* m_lineEdit;
    QStandardItemModel* m_model;
};


#if 1 //MyTableView
//////////////////////////////////////////////////////////////////////////
#include <QTableView>
#include <QHeaderView>
//
class MyTableView :public QTableView
{
    Q_OBJECT//因为这个宏的原因,类的定义,需要放置到头文件中.
public:
    explicit MyTableView(QWidget *parent = Q_NULLPTR);
protected:
    void paintEvent(QPaintEvent *e) Q_DECL_OVERRIDE;
    void resizeEvent(QResizeEvent *event) Q_DECL_OVERRIDE;
};
//
inline MyTableView::MyTableView(QWidget *parent /* = Q_NULLPTR */) :QTableView(parent) {}
//
inline void MyTableView::paintEvent(QPaintEvent *e)
{
    int rowCount = this->verticalHeader()->count();
    int colCount = this->horizontalHeader()->count();
    if (0 < rowCount)
    {
        int rSize = (this->height() - rowCount) / rowCount;
        this->verticalHeader()->setDefaultSectionSize(rSize);
    }
    if (0 < colCount)
    {
        int cSize = (this->width() - colCount) / colCount;
        this->horizontalHeader()->setDefaultSectionSize(cSize);
    }
    return QTableView::paintEvent(e);
}
//
inline void MyTableView::resizeEvent(QResizeEvent *event)
{
    return QTableView::resizeEvent(event);
}
//////////////////////////////////////////////////////////////////////////
#endif//MyTableView


#endif // MAINWINDOW_H
