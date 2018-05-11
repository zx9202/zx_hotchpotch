#include "mainwindow.h"
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>
#include <QTableView>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    createUi();
}

MainWindow::~MainWindow()
{

}

void MainWindow::createUi()
{
    QWidget* mainWidget = new QWidget(this);
    {
        QVBoxLayout* mainLayout = new QVBoxLayout(mainWidget);
        mainLayout->setSpacing(0);
        mainLayout->setMargin(0);
        if (true) {
            m_lineEdit = new QLineEdit(mainWidget);
            mainLayout->addWidget(m_lineEdit);
        }
        if (true) {
            QPushButton* btn4LineEdit = new QPushButton(tr("btn4LineEdit"), mainWidget);
            connect(btn4LineEdit, SIGNAL(clicked()), this, SLOT(slotClicked()));
            mainLayout->addWidget(btn4LineEdit);
        }
        if (true) {
            QTableView* tableView = new MyTableView(mainWidget);
            tableView->setShowGrid(true);
            tableView->setEditTriggers(QAbstractItemView::NoEditTriggers);//设置表格只读,不能进行编辑.
            tableView->verticalHeader()->setVisible(false); //隐藏列表头.
            tableView->horizontalHeader()->setVisible(false); //隐藏行表头.
            {
                m_model = new QStandardItemModel(mainWidget);
                int rowCount = 3, colCount = 4;
                m_model->setRowCount(rowCount);
                m_model->setColumnCount(colCount);
                for (int r = 0; r < rowCount; ++r)
                {
                    for (int c = 0; c < colCount; ++c)
                    {
                        QModelIndex idx = m_model->index(r, c, QModelIndex());
                        m_model->setData(idx, QVariant(r*colCount + c));
                    }
                }
                tableView->setModel(m_model);
            }
            connect(tableView, SIGNAL(doubleClicked(const QModelIndex&)), this, SLOT(slotDoubleClicked(const QModelIndex&)));
            mainLayout->addWidget(tableView);
        }
        //mainLayout->addStretch();//添加伸缩
        mainWidget->setLayout(mainLayout);
    }
    setCentralWidget(mainWidget);
}

void MainWindow::slotClicked()
{
    QMessageBox::information(nullptr, "slotClicked", m_lineEdit->text());
}

void MainWindow::slotDoubleClicked(const QModelIndex &index)
{
    if (!index.isValid())
        return;
    index.row(); index.column();
    QVariant itemData = m_model->data(index);
    QMessageBox::information(nullptr, "slotDoubleClicked", itemData.toString());
}
